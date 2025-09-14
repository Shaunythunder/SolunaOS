-- lib/core/system.lua
-- Provides core operating system functionality for SolunaOS
local system = {}

function system.runApp(App_name)
    local app = require(App_name)
    local app_instance = app.new()
    app_instance:run()
end

--- Gets amount of free memory in the OS.
--- @return number memory bytes
function system.freeMemory()
    return computer.freeMemory()
end

--- Gets the amount of total memory in the OS.
--- @return number memory bytes
function system.totalMemory()
    return computer.totalMemory()
end

function system.usedMemory()
    return computer.totalMemory() - computer.freeMemory()
end

function system.queueEvent(event, ...)
    return computer.pushSignal(event, ...)
end

--- Reboots the computer.
function system.reboot()
    computer.shutdown(true)
end

--- Shuts down the computer.
function system.shutdown()
    computer.shutdown(false)
end

--- Sleeps for a specified duration.
--- @param slp_dur number
function system.sleep(slp_dur)
    assert(type(slp_dur) == "number", "Duration must be a number")
    local sleep_end = computer.uptime() + slp_dur
    while sleep_end > computer.uptime() do
        computer.pullSignal(0.1)
    end
end

--- The length of time the computer has been on
--- @return number -- seconds
function system.uptime()
    return computer.uptime()
end

--- Gets the version of the operating system.
--- @return string version
function system.version()
    return _G.OS_VERSION or "Unknown SolunaOS Version"
end

-- Freezes the OS for debugging purposes. Requires manual reboot once used.
function system.freeze()
    while true do
        system.sleep(1)
    end
end

return system