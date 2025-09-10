-- /lib/core/shell/commands/environment/alias.lua

local alias = {}
alias.description = "Set or view command aliases that act as shortcuts for longer commands. For example 'root' -> 'cd /'"
alias.usage = "Usage: alias [name] ['command']"
alias.flags = {}

    -- Sets a command alias
    function alias.execute(args, _, shell)
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
            return alias.usage
        end
    end

return alias