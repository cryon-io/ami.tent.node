local _amiId = "TENT node"

return {
    title = _amiId,
    commands = {
        info = {
            description = "ami 'info' sub command",
            summary = "Prints runtime info and status of the app",
            action = "__tent/info.lua",
            contextFailExitCode = EXIT_APP_INFO_ERROR
        },
        setup = {
            options = {
                configure = {
                    description = "Configures application, renders templates and installs services"
                }
            },
            action = function(_options, _, _, _cli)
                local _noOptions = #table.keys(_options) == 0
                if _noOptions or _options.environment then
                    am.app.prepare()
                end

                if _noOptions or not _options["no-validate"] then
                    am.execute("validate", {"--platform"})
                end

                if _noOptions or _options.app then
                    am.execute_extension("__btc/download-binaries.lua", { contextFailExitCode = EXIT_SETUP_ERROR })
                end

                if _noOptions and not _options["no-validate"] then
                    am.execute("validate", {"--configuration"})
                end

                if _noOptions or _options.configure then
                    am.app.render()

                    am.execute_extension("__btc/configure.lua", { contextFailExitCode = EXIT_APP_CONFIGURE_ERROR })
                    am.execute_extension("__tent/configure.lua", { contextFailExitCode = EXIT_APP_CONFIGURE_ERROR })
                end
                log_success("TENT node setup complete.")
            end
        },
        start = {
            description = "ami 'start' sub command",
            summary = "Starts the TENT node",
            type = "extension",
            action = "__btc/start.lua",
            contextFailExitCode = EXIT_APP_START_ERROR
        },
        stop = {
            description = "ami 'stop' sub command",
            summary = "Stops the TENT node",
            action = "__btc/stop.lua",
            contextFailExitCode = EXIT_APP_STOP_ERROR
        },
        validate = {
            description = "ami 'validate' sub command",
            summary = "Validates app configuration and platform support",
            action = function(_options, _, _, _cli)
                -- //TODO: Validate platform
                -- //TODO: add switches
                ami_assert(proc.EPROC, "TENT node AMI requires extra api - eli.proc.extra", EXIT_MISSING_API)
                ami_assert(fs.EFS, "TENT node AMI requires extra api - eli.fs.extra", EXIT_MISSING_API)

                ami_assert(type(am.app.get("id")) == "string", "id not specified!", EXIT_INVALID_CONFIGURATION)
                ami_assert(
                    type(am.app.get_config()) == "table",
                    "configuration not found in app.h/json!",
                    EXIT_INVALID_CONFIGURATION
                )
                ami_assert(type(am.app.get("user")) == "string", "USER not specified!", EXIT_INVALID_CONFIGURATION)
                ami_assert(
                    type(am.app.get_type()) == "table" or type(am.app.get_type()) == "string",
                    "Invalid app type!",
                    EXIT_INVALID_CONFIGURATION
                )
                log_success("TENT masternode configuration validated.")
            end
        },
        about = {
            description = "ami 'about' sub command",
            summary = "Prints information about application",
            action = function(_options, _, _, _cli)
                local _ok, _aboutFile = fs.safe_read_file("__tent/about.hjson")
                ami_assert(_ok, "Failed to read about file!", EXIT_APP_ABOUT_ERROR)

                local _ok, _about = hjson.safe_parse(_aboutFile)
                _about["App Type"] = am.app.get({"type", "id"}, am.app.get("type"))
                ami_assert(_ok, "Failed to parse about file!", EXIT_APP_ABOUT_ERROR)
                if am.options.OUTPUT_FORMAT == "json" then
                    print(hjson.stringify_to_json(_about, {indent = false, skipkeys = true}))
                else
                    print(hjson.stringify(_about))
                end
            end
        },
        removedb = {
            index = 6,
            description = "snowgemd 'removedb' command",
            summary = "Removes snowgemd database",
            options = {
                help = HELP_OPTION
            },
            action = "__btc/removedb.lua",
            contextFailExitCode = EXIT_RM_DATA_ERROR
        },
        remove = {
            index = 7,
            action = function(_options, _, _, _cli)
                if _options.all then
                    am.execute_extension("__btc/remove-all.lua", { contextFailExitCode = EXIT_RM_ERROR })
                    am.execute_extension("__tent/remove-all.lua", { contextFailExitCode = EXIT_RM_ERROR })
                    am.app.remove()
                    log_success("Application removed.")
                else
                    am.app.remove_data()
                    log_success("Application data removed.")
                end
                return
            end
        }
    }
}
