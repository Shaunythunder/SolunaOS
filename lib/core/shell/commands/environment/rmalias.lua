-- /lib/core/shell/commands/environment/rmalias.lua

local rmalias = {}
rmalias.description = "Removes all command aliases"
rmalias.usage = "Usage: rmalias"
rmalias.flags = {}

    -- Removes all command aliases
    function rmalias.execute(args, _, shell)
        if #args ~= 0 then
            return rmalias.usage
        end

        shell:resetAliases()
        return ""
    end

return rmalias