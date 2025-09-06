-- /lib/core/shell/commands/terminal/clear.lua
local clear = {}

function clear.execute(args, input_data, shell)
    if args and #args > 0 then
        return "Usage: clear"
    end
    
    shell:clear()
    return ""
end

return clear
