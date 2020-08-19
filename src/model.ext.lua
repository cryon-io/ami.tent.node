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

local _masternodeConf = eliUtil.merge_tables(APP.configuration.MASTERNODE_CONFIGURATION or {}, {
    alias = APP.id,
    ip = type(APP.configuration.DAEMON_CONFIGURATION) == 'table' and APP.configuration.DAEMON_CONFIGURATION.bind or APP.configuration.DAEMON_CONFIGURATION.externalip,
    port = type(APP.configuration.port) == 'table' and APP.configuration.DAEMON_CONFIGURATION.port or 16113,
})

_masternodeConf.ip = type(_masternodeConf.ip) == "string" and string.match(_masternodeConf.ip, ":") and '[' .. _masternodeConf.ip .. ']' or _masternodeConf.ip

APP.model = eliUtil.merge_tables(
    APP.model,
    {
        DAEMON_CONFIGURATION = {
            rpcuser = APP.configuration.RPC_USER or APP.user,
            rpcpassword = APP.configuration.RPC_PASS or _rpcPass,
            server = (type(APP.configuration.NODE_PRIVKEY) == 'string' or APP.configuration.SERVER) and 1 or nil,
            listen = (type(APP.configuration.NODE_PRIVKEY) == 'string' or APP.configuration.SERVER) and 1 or nil,
            masternodeprivkey = APP.configuration.NODE_PRIVKEY,
            masternode = APP.configuration.NODE_PRIVKEY and 1,
        },
        MASTERNODE_CONFIGURATION = _masternodeConf,
        DAEMON_NAME = "snowgemd",
        CLI_NAME = "snowgem-cli",
        CONF_NAME = "snowgem.conf",
        CONF_SOURCE = "__btc/assets/daemon.conf",
        MN_CONF_NAME = "masternode.conf",
        MN_CONF_SOURCE = "__xsg/assets/masternode.conf",
        SERVICE_NAME = "snowgemd",
        DATA_DIR = "data"
    }, true
)