-- lib/core/os.lua
-- Provides core operating system functionality for SolunaOS
local os = {}

    local env = {}

    --- Gets the value of an environment variable.
    --- @param env_var string
    --- @return string|nil env
    function os.getenv(env_var)
        return env[env_var]
    end

    --- Removes an environment variable.
    --- @param var string -- The name of the environment variable.
    --- @return nil
    function os.removeenv(var)
        env[var] = nil
    end

    --- Sets an environment variable to a value.
    --- @param env_var string
    --- @param env_val string 
    function os.setenv(env_var, env_val)
        env[env_var] = env_val
    end

    function os.runApp(App_name)
        local app = require(App_name)
        local app_instance = app.new()
        app_instance:run()
    end

    --- Gets amount of free memory in the OS.
    --- @return number memory bytes
    function os.freeMemory()
        return computer.freeMemory()
    end

    --- Gets the amount of total memory in the OS.
    --- @return number memory bytes
    function os.totalMemory()
        return computer.totalMemory()
    end

    function os.queueEvent(event, ...)
        return computer.pushSignal(event, ...)
    end

    --- Reboots the computer.
    function os.reboot()
        computer.shutdown(true)
    end

    --- Shuts down the computer.
    function os.shutdown()
        computer.shutdown(false)
    end

    --- Sleeps for a specified duration.
    --- @param sleep_duration number
    function os.sleep(sleep_duration)
        assert(type(sleep_duration) == "number", "Duration must be a number")
        local sleep_end = computer.uptime() + sleep_duration
        while sleep_end > computer.uptime() do
            computer.pullSignal(0.1)
        end
    end

    --- The length of time the computer has been on
    --- @return number -- seconds
    function os.uptime()
        return computer.uptime()
    end

    --- Gets the version of the operating system.
    --- @return string version
    function os.version()
        return _G.OS_VERSION or "Unknown SolunaOS Version"
    end

return os