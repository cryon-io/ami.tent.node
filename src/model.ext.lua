am.app.set_model(
    {
        DAEMON_CONFIGURATION = {
            server = (type(am.app.get_config("NODE_PRIVKEY") == "string") or am.app.get_config("SERVER")) and 1 or nil,
            listen = (type(am.app.get_config("NODE_PRIVKEY") == "string") or am.app.get_config("SERVER")) and 1 or nil,
            masternodeprivkey = am.app.get_config("NODE_PRIVKEY"),
            masternode = am.app.get_config("NODE_PRIVKEY") and 1 or nil
        },
        DAEMON_NAME = "snowgemd",
        CLI_NAME = "snowgem-cli",
        CONF_NAME = "snowgem.conf",
        CONF_SOURCE = "__btc/assets/daemon.conf",
        MN_CONF_NAME = "masternode.conf",
        MN_CONF_SOURCE = "__tent/assets/masternode.conf",
        SERVICE_NAME = "snowgemd",
        DATA_DIR = "data"
    },
    { merge = true, overwrite = true }
)