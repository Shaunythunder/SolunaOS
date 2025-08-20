-- /lib/core/shell/commands/system/shutdown.lua
local os = require("os")

local shutdown = {}

    -- Shuts down the system
    function shutdown.execute(args, input_data, shell)
        if #args > 0 then
            return "Usage: shutdown"
        end

        os.shutdown()
    end

return shutdown