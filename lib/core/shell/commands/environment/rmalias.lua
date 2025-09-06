-- /lib/core/shell/commands/environment/rmalias.lua

local rmalias = {}

    -- Removes all command aliases
    function rmalias.execute(args, input_data, shell)
        if #args ~= 0 then
            return "Usage: rmalias"
        end

        shell:resetAliases()
        return ""
    end

return rmalias