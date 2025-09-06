-- /lib/core/shell/commands/environment/alias.lua

local alias = {}

    -- Sets a command alias
    function alias.execute(args, input_data, shell)
        if #args == 0 then
            if not shell.aliases or next(shell.aliases) == nil then
                return "No aliases set"
            end
            local result = ""
            for name, command in pairs(shell.aliases) do
                result = result .. name .. " = '" .. command .. "'\n"
            end
            return result
        elseif #args == 1 then
            local name = args[1]
            if shell.aliases[name] then
                return name .. " = '" .. shell.aliases[name] .. "'"
            else
                return "Alias not found: " .. name
            end
        elseif #args == 2 then
            local name = args[1]
            local command = args[2]
            shell:saveAlias(name, command)
            return "Alias set: " .. name .. " = '" .. command .. "'"
        else
            return "Usage: alias [name] ['command']"
        end
    end

return alias