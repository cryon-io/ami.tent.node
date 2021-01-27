local _user = am.app.get("user")
ami_assert(type(_user) == "string", "User not specified...")

local _ok, _apt = am.plugin.safe_get("apt")
if not _ok then
    log_warn("Failed to load apt plugin!")
end

local _ok, _code, _, _error, _dep = _apt.install("libgomp1")
if not _ok then 
    log_warn("Failed to install " .. (_dep or '-').. "! - " .. _error)
end

local DATA_PATH = am.app.get_model("DATA_DIR", "data")
fs.safe_mkdirp(DATA_PATH)

local _confDest = path.combine(DATA_PATH, am.app.get_model("MN_CONF_NAME"))
local _ok, _error = fs.safe_copy_file(am.app.get_model("MN_CONF_SOURCE"), _confDest)
ami_assert(_ok, "Failed to deploy " .. am.app.get_model("MN_CONF_NAME", "unidentified") .. ": " .. (_error or ""))

local _fetchScriptPath = "bin/fetch-params.sh"
local _ok, _error = net.safe_download_file("https://raw.githubusercontent.com/Snowgem/Snowgem/master/zcutil/fetch-params.sh", _fetchScriptPath, {followRedirects = true})
if not _ok then 
    log_error("Failed to download fetch-params.sh - " .. (_error or '-').. "!")
    return
end

if fs.exists(_fetchScriptPath) then -- we download only on debian
    log_info("Downloading params... (This may take few minutes.)")
    local _proc = proc.spawn("/bin/bash", { _fetchScriptPath }, {
        stdio = { stderr = "pipe" },
        wait = true,
        env = { HOME = "/home/" .. _user }
    })
    ami_assert(_proc.exitcode == 0, "Failed to fetch params: " .. _proc.stderrStream:read("a"))
    log_success("Sprout parameters downloaded...")
end