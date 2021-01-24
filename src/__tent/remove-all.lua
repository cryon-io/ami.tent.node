local _user = am.app.get("user")
ami_assert(type(_user) == "string", "User not specified...")

local _ok, _paths = fs.safe_read_dir("/home/" .. _user .. "/.zcash-params", {recurse = true, returnFullPaths = true})
if not _ok then
    return -- dir does not exist
end
for _, path in ipairs(_paths) do
    local _ok, _error = fs.safe_remove(path)
    ami_assert(_ok, "Failed to remove app data - " .. tostring(_error) .. "!")
end