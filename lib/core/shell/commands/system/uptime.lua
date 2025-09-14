-- /lib/core/shell/commands/system/uptime.lua

local sys = require("system")

local uptime = {}
uptime.description = "Displays system uptime"
uptime.usage = "Usage: uptime"
uptime.flags = {}

-- Gets the system uptime
function uptime.execute(args, _, _)
    if #args > 0 then
        return uptime.usage
    end

    local os_uptime = sys.uptime()
    print("System Uptime: " .. os_uptime .. " seconds")
    return ""
end

return uptime
