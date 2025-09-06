-- /lib/core/shell/commands/environment/unalias.lua

local unalias = {}

    -- Unsets a command alias
    function unalias.execute(args, input_data, shell)
        if #args == 0 or #args > 1 then
            return "Usage: unalias [name]"
        end

        local name = args[1]
        if shell.aliases[name] then
            shell:removeAlias(name)
            return "Alias removed: " .. name
        else
            return "Alias not found: " .. name
        end
    end

return unalias