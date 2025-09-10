-- /lib/core/shell/commands/environment/unalias.lua

local unalias = {}
unalias.description = "Unset a command alias"
unalias.usage = "Usage: unalias <name>"
unalias.flags = {}

    -- Unsets a command alias
    function unalias.execute(args, _, shell)
        if #args == 0 or #args > 1 then
            return unalias.usage
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