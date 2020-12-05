APP.model =
    eliUtil.merge_tables(
    APP.model,
    {
        DAEMON_CONFIGURATION = eliUtil.merge_tables(
            {
                server = (type(APP.configuration.NODE_PRIVKEY) == "string" or APP.configuration.SERVER) and 1 or nil,
                listen = (type(APP.configuration.NODE_PRIVKEY) == "string" or APP.configuration.SERVER) and 1 or nil,
                masternodeprivkey = APP.configuration.NODE_PRIVKEY,
                masternode = APP.configuration.NODE_PRIVKEY and 1
            },
            _daemonConfiguration
        ),
        DAEMON_NAME = "snowgemd",
        CLI_NAME = "snowgem-cli",
        CONF_NAME = "snowgem.conf",
        CONF_SOURCE = "__btc/assets/daemon.conf",
        MN_CONF_NAME = "masternode.conf",
        MN_CONF_SOURCE = "__xsg/assets/masternode.conf",
        SERVICE_NAME = "snowgemd",
        DATA_DIR = "data"
    },
    true
)
