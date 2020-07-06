local _user = APP.user
ami_assert(type(_user) == "string", "User not specified...")

local _ok, _apt = safe_load_plugin("apt")
if not _ok then 
    log_warn("Failed to load apt plugin!")
end

local _ok, _code, _, _error, _dep = _apt.install("libgomp1")
if not _ok then 
    log_warn("Failed to install " .. (_dep or '-').. "! - " .. _error)
end

local _fetchScriptPath = "bin/fetch-params.sh"
local _ok, _error = eliNet.safe_download_file("https://raw.githubusercontent.com/Snowgem/Snowgem/master/zcutil/fetch-params.sh", _fetchScriptPath, {followRedirects = true})
if not _ok then 
    log_error("Failed to download fetch-params.sh - " .. (_error or '-').. "!")
    return
end

local function _download_params()
    local _rd, _proc_wr = eliFs.pipe()
    local _rderr, _proc_werr = eliFs.pipe()
    local _ok, _env = eliEnv.safe_environment()
    if not _ok then
        ami_error("Failed to get env variables " .. (_env or ""), EXIT_APP_CONFIGURE_ERROR)
    end
    _env.HOME = "/home/" .. _user

    local _proc, _err = eliProc.spawn {"/bin/bash", args = { _fetchScriptPath }, stdout = _proc_wr, stderr = _proc_werr, env = _env}
    _proc_wr:close()
    _proc_werr:close()

    if not _proc then
        _rd:close()
        _rderr:close()
        ami_error("Failed to fetch params", EXIT_APP_INTERNAL_ERROR)
    end
    local _exitcode = _proc:wait()
    local _stdout = _rd:read("a")
    local _stderr = _rderr:read("a")
    ami_assert(_exitcode == 0, "Failed to fetch params: " .. _stderr, EXIT_APP_CONFIGURE_ERROR)
end

if eliFs.exists(_fetchScriptPath) then -- we download only on debian
    log_info("Downloading params... (This may take few minutes.)")
    _download_params()
    log_success("Sprout parameters downloaded...")
end
