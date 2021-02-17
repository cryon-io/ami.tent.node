local _json = am.options.OUTPUT_FORMAT == "json"

local _ok, _systemctl = am.plugin.safe_get("systemctl")
ami_assert(_ok, "Failed to load systemctl plugin", EXIT_PLUGIN_LOAD_ERROR)

local _appId = am.app.get("id", "unknown")
local _serviceName = am.app.get_model("SERVICE_NAME", "unknown")
local _ok, _status, _started = _systemctl.safe_get_service_status(_appId .. "-" .. _serviceName)
ami_assert(_ok, "Failed to start " .. _appId .. "-" .. _serviceName .. ".service " .. (_status or ""), EXIT_PLUGIN_EXEC_ERROR)

local _info = {
    snowgemd = _status,
    started = _started,
    level = "ok",
    synced = false,
    status = "TENT node down",
    version = am.app.get_version(),
    type = am.app.get_type()
}

local function _exec_tent_cli(...)
    local arg = {"-datadir=data", ...}
    local _rpcBind = am.app.get_config({"DAEMON_CONFIGURATION", "rpcbind"})
    if type(_rpcBind) == "string" then
        table.insert(arg, 1, "-rpcconnect=" .. _rpcBind)
    end
    local _cmd = string.join_strings(" ", table.unpack(arg))
    local _proc = proc.spawn("bin/snowgem-cli", arg, { stdio = { stdout = "pipe", stderr = "pipe" }, wait = true})

    local _exitcode = _proc.exitcode
    local _stdout = _proc.stdoutStream:read("a") or ""
    local _stderr = _proc.stderrStream:read("a") or ""
    return _exitcode, _stdout, _stderr
end

local function _get_tent_cli_result(exitcode, stdout, stderr)
    if exitcode ~= 0 then
        local _errorInfo = stderr:match("error: (.*)")
        local _ok, _output = hjson.safe_parse(_errorInfo)
        if _ok then
            return false, _output
        end
        return false, {message = "unknown (internal error)"}
    end

    local _ok, _output = hjson.safe_parse(stdout)
    if _ok then
        return true, _output
    end
    return false, {message = "unknown (internal error)"}
end

local function _update_info(update_function)
    if _info.level ~= "ok" or type(update_function) ~= "function" then
        return
    end
    update_function()
end

if _info.snowgemd == "running" then
    local _checks = {
        function()
            -- blockchain info check
            local _exitcode, _stdout, _stderr = _exec_tent_cli("getblockchaininfo")
            local _success, _output = _get_tent_cli_result(_exitcode, _stdout, _stderr)

            _info.currentBlock = _success and _output.blocks or "unknown"
            _info.currentBlockHash = _success and _output.bestblockhash or "unknown"
        end,
        function()
            -- synchronization check
            local _exitcode, _stdout, _stderr = _exec_tent_cli("getblockchainsyncstatus")
            local _success, _output = _get_tent_cli_result(_exitcode, _stdout, _stderr)

            if _success then
                if _output.IsBlockchainSync == true then
                    _info.status = "Synced"
                    _info.synced = true
                else
                    _info.level = "warn"
                    _info.status = "Syncing..."
                end
                return
            end

            if type(_stderr) ~= "string" then
                _stderr = ""
            end

            _info.level = "warn"
            _info.status = _stderr:match("Snowgem is not connected!") or
                _stderr:match("Snowgem is downloading blocks...") or
                "Unknown error..."
        end,
        function()
            -- masternode status check
            if am.app.get_config({"DAEMON_CONFIGURATION", "masternode"}) == 1 then
                local _, _stdout, _stderr = _exec_tent_cli("masternode", "debug")
                if type(_stdout) ~= "string" then
                    _stdout = ""
                end

                if _stdout:match("Masternode successfully started") then
                    _info.status = "Masternode successfully started"
                    return
                end

                if type(_stderr) ~= "string" then
                    _stderr = ""
                end

                local _warnMsg = _stdout:match("Hot node, waiting for remote activation") or
                    _stderr:match("Hot node, waiting for remote activation") or
                    _stdout:match("Node just started, not yet activated") or
                    _stderr:match("Node just started, not yet activated")

                _info.level = _warnMsg and "warn" or "error"
                _info.status = _warnMsg or
                    _stderr:match("error message:.-\n(.-)\n%s*") or
                    _stdout:match("error message:.-\n(.-)\n%s*") or
                    "Failed to verify masternode status!"
            else
                _info.status = "TENT node up"
            end
        end
    }

    for _, check in ipairs(_checks) do
        _update_info(check)
    end
else
    _info.level = "error"
    _info.status = "Node is not running!"
end

if _json then
    print(hjson.stringify_to_json(_info, {indent = false}))
else
    print(hjson.stringify(_info))
end