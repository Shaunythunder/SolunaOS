-- lib/core/shell/commands/filesystem/mkdir.lua
local fs = require("filesystem")

local mkdir = {}

    -- Creates a directory with the specified name
    function mkdir.execute(args, input_data, shell)
        if #args == 0 then
            return "Usage: mkdir <directory>"
        end

        local dirname = args[1]

        if fs.exists(dirname) then
            return "Error: Directory already exists: " .. dirname
        end

        local success, err = fs.makeDirectory(dirname)
        if not success then
            return "Error: Unable to create directory: " .. err
        end

        return ""
    end

return mkdir