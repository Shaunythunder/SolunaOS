-- /lib/core/shell/commands/terminal/clear.lua
local clear = {}
clear.description = "Clears the terminal screen"
clear.usage = "Usage: clear"
clear.flags = {}

    function clear.execute(args, input_data, shell)
        if #args > 0 then
            return clear.usage
        end

        shell:clear()
        return ""
    end

return clear
