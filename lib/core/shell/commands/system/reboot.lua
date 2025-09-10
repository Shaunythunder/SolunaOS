-- /lib/core/shell/commands/system/reboot.lua

local sys = require("system")

local reboot = {}
reboot.description = "Reboots the system"
reboot.usage = "Usage: reboot"
reboot.flags = {}

    -- Reboots the system
    function reboot.execute(args, _, _)
        if #args > 0 then
            return reboot.usage
        end

        sys.reboot()
    end

return reboot
