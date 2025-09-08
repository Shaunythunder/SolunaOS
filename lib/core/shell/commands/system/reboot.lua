-- /lib/core/shell/commands/system/reboot.lua
local os = require("os")

local reboot = {}
reboot.description = "Reboots the system"
reboot.usage = "Usage: reboot"
reboot.flags = {}

    -- Reboots the system
    function reboot.execute(args, input_data, shell)
        if #args > 0 then
            return reboot.usage
        end

        os.reboot()
    end

return reboot
