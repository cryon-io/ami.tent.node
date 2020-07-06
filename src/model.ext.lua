if type(APP.model) ~= "table" then
    APP.model = {}
end

if type(APP.configuration) ~= 'table' then
    ami_error("Configuration not found...", EXIT_INVALID_CONFIGURATION) 
end

local _charsetTable = {}
_charset="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
_charset:gsub(".",function(c) table.insert(_charsetTable,c) end)
local _rpcPass = eliUtil.random_string(20, _charsetTable)

APP.model = eliUtil.merge_tables(
    APP.model,
    {
        RPC_USER = APP.user,
        RPC_PASS = APP.configuration.RPC_PASS or _rpcPass,
        RPC_PORT = APP.configuration.RPC_PORT or 16111,
        IS_SERVER = type(APP.configuration.NODE_PRIVKEY) == 'string' or APP.configuration.SERVER,
        DAEMON_NAME = "snowgemd",
        CLI_NAME = "snowgem-cli",
        CONF_NAME = "snowgem.conf",
        CONF_SOURCE = "__btc/assets/daemon.conf",
        SERVICE_NAME = "snowgemd",
        DATA_DIR = "data"
    },true
)