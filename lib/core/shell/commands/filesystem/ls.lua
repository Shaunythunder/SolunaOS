-- lib/core/shell/commands/filesystem/ls.lua
local fs = require("filesystem")
local ls = {}

    -- This command lists the files in a directory.
    function ls.execute(args, input_data, shell)
        local directory = args[1] or shell.current_dir
        local files = fs.list(directory)
        if files then
            return table.concat(files, " ")
        else
            return "Error: Unable to list directory " .. directory
        end
    end

return ls