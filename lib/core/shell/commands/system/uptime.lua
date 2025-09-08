-- /lib/core/shell/commands/system/uptime.lua
local os = require("os")

local uptime = {}
uptime.description = "Displays system uptime"
uptime.usage = "Usage: uptime"
uptime.flags = {}

    -- Gets the system uptime
    function uptime.execute(args, input_data, shell)
        if #args > 0 then
            return uptime.usage
        end

        local os_uptime = os.uptime()
        print("System Uptime: " .. os_uptime .. " seconds")
        return ""
    end

return uptime
