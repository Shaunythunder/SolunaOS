-- /lib/core/shell/commands/system/reboot.lua
local os = require("os")

local reboot = {}

    -- Reboots the system
    function reboot.execute(args, input_data, shell)
        if #args > 0 then
            return "Usage: reboot"
        end

        os.reboot()
    end

return reboot
