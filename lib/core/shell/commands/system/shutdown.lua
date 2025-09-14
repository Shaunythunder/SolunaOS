-- /lib/core/shell/commands/system/shutdown.lua

local sys = require("system")

local shutdown = {}
shutdown.description = "Shuts down the system"
shutdown.usage = "Usage: shutdown"
shutdown.flags = {}

    -- Shuts down the system
    function shutdown.execute(args, _, _)
        local args = args or {}
        if #args > 0 then
            return shutdown.usage
        end

        sys.shutdown()
    end

return shutdown