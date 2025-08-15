-- lib/core/os.lua
-- Provides core operating system functionality for SolunaOS
local os = {}

    local environment = {}

    --- Gets the value of an environment variable.
    --- @param variable string -- The name of the environment variable.
    --- @return string|nil -- The value of the environment variable or nil if not set.
    function os.getenv(variable)
        assert(type(variable) == "string", "Variable name must be a string")
        return environment[variable]
    end

    --- Removes an environment variable.
    --- @param variable string -- The name of the environment variable.
    --- @return nil
    function os.removeenv(variable)
        assert(type(variable) == "string", "Variable name must be a string")
        environment[variable] = nil
    end

    --- Sets an environment variable.
    --- @param variable string -- The name of the environment variable.
    --- @param value string -- The value to set the environment variable to.
    function os.setenv(variable, value)
        assert(type(variable) == "string", "Variable name must be a string")
        assert(type(value) == "string", "Variable value must be a string")
        environment[variable] = value
    end

    --- Returns the amount of free memory in the system.
    --- @return number -- The amount of free memory in bytes.
    function os.freeMemory()
        return computer.freeMemory()
    end

    --- Returns the amount of total memory in the system.
    --- @return number -- The amount of total memory in bytes.
    function os.totalMemory()
        return computer.totalMemory()
    end

    function os.queueEvent(event, ...)
        return computer.pushSignal(event, ...)
    end

    --- Reboots the computer.
    --- @return nil
    function os.reboot()
        computer.shutdown(true)
    end

    --- Shuts down the computer.
    --- @return nil
    function os.shutdown()
        computer.shutdown(false)
    end

    --- Sleeps for a specified duration.
    --- @param duration number -- The duration to sleep for, in seconds.
    --- @return nil
    function os.sleep(duration)
        assert(type(duration) == "number", "Duration must be a number")
        local sleep_end = computer.uptime() + duration
        while sleep_end > computer.uptime() do
            computer.pullSignal(0.1)
        end
    end

    --- Returns the uptime of the computer in seconds.
    --- @return number -- The uptime of the computer in seconds.
    function os.uptime()
        return computer.uptime()
    end

    --- Returns the version of the operating system.
    --- @return string -- The version of the operating system.
    function os.version()
        return _G.OS_VERSION or "Unknown SolunaOS Version"
    end

return os