local _json = ...
local _hjson = require "hjson"

local _ok, _systemctl = safe_load_plugin("systemctl")
ami_assert(_ok, "Failed to load systemctl plugin", EXIT_PLUGIN_LOAD_ERROR)

local _ok, _status, _started = _systemctl.safe_get_service_status(APP.id .. "-" .. APP.model.SERVICE_NAME)
ami_assert(_ok, "Failed to start " .. APP.id .. "-" .. APP.model.SERVICE_NAME .. ".service " .. (_status or ""), EXIT_PLUGIN_EXEC_ERROR)

local _info = {
    snowgemd = _status,
    started = _started,
    level = "ok",
    synced = "not reported",
    status = "XSG node down"
}

local function _exec_xsg_cli(...)
    local arg = {"-datadir=data", ...}
    if type(APP.configuration.DAEMON_CONFIGURATION) == "table" and type(APP.configuration.DAEMON_CONFIGURATION.rpcbind) == "string" then
        table.insert(arg, 1, "-rpcconnect=" .. APP.configuration.DAEMON_CONFIGURATION.rpcbind)
    end
    local _cmd = exString.join_strings(" ", table.unpack(arg))
    local _rd, _proc_wr = eliFs.pipe()
    local _rderr, _proc_werr = eliFs.pipe()
    local _proc, _err = eliProc.spawn {"bin/snowgem-cli", args = arg, stdout = _proc_wr, stderr = _proc_werr}
    _proc_wr:close()
    _proc_werr:close()

    if not _proc then
        _rd:close()
        _rderr:close()
        ami_error("Failed to execute snowgem-cli command: " .. _cmd, EXIT_APP_INTERNAL_ERROR)
    end
    local _exitcode = _proc:wait()
    local _stdout = _rd:read("a")
    local _stderr = _rderr:read("a")
    --ami_assert(_exitcode == 0, "Failed to execute snowgem-cli command: " .. _cmd, EXIT_APP_INTERNAL_ERROR)
    return _exitcode, _stdout, _stderr
end

local function _get_xsg_cli_result(exitcode, stdout, stderr)
    if exitcode ~= 0 then
        local _errorInfo = stderr:match("error: (.*)")
        local _ok, _output = pcall(_hjson.parse, _errorInfo)
        if _ok then
            return false, _output
        end
        return false, {message = "unknown (internal error)"}
    end

    local _ok, _output = pcall(_hjson.parse, stdout)
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
            local _exitcode, _stdout, _stderr = _exec_xsg_cli("getblockchaininfo")
            local _success, _output = _get_xsg_cli_result(_exitcode, _stdout, _stderr)

            _info.currentBlock = _success and _output.blocks or "unknown"
            _info.currentBlockHash = _success and _output.bestblockhash or "unknown"
        end,
        function()
            -- synchronization check
            local _exitcode, _stdout, _stderr = _exec_xsg_cli("getblockchainsyncstatus")
            local _success, _output = _get_xsg_cli_result(_exitcode, _stdout, _stderr)

            if _success then
                if _output.IsBlockchainSync == true then
                    _info.status = "Synced"
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
            if type(APP.configuration.DAEMON_CONFIGURATION) == "table" and tonumber(APP.configuration.DAEMON_CONFIGURATION.masternode) == 1 then
                local _, _stdout, _stderr = _exec_xsg_cli("masternode", "debug")
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
                _info.status = "XSG node up"
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

_info.version = get_app_version()
_info.type = APP.type.id

if _json then
    print(_hjson.stringify_to_json(_info, {indent = false}))
else
    print(_hjson.stringify(_info))
end