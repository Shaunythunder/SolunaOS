-- lib/core/shell/commands/navigation/pwd.lua

local pwd = {}

-- This command prints the current working directory.
function pwd.execute(args, input_data, shell)
    return shell.current_dir or "/"
end

return pwd