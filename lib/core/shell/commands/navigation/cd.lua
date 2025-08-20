-- lib/core/shell/commands/navigation/cd.lua
local fs = require("filesystem")
local cd = {}

    -- This command changes the current directory of the shell.
    function cd.execute(args, input_data, shell)
        local target_dir = args[1] or "/"

        if fs.exists(target_dir) and fs.isDirectory(target_dir) then
            shell.current_dir = target_dir
            return ""
        else
            return "Directory not found: " .. target_dir
        end
    end

return cd