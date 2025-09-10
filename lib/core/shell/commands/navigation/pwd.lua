-- lib/core/shell/commands/navigation/pwd.lua

local pwd = {}
pwd.description = "Prints the current working directory"
pwd.usage = "Usage: pwd"
pwd.flags = {}

-- This command prints the current working directory.
function pwd.execute(args, _, shell)
    if #args ~= 0 then
        return pwd.usage
    end

    return shell.current_dir or "/"
end

return pwd