-- lib/core/shell/commands/filesystem/touch.lua

local fs = require("filesystem")

local touch = {}
touch.description = "Creates an empty file or updates the timestamp of an existing file"
touch.usage = "Usage: touch <file>"
touch.flags = {}

    -- Creates an empty file or updates the timestamp of an existing file
    function touch.execute(args, input_data, shell)
        if #args == 0 then
            return touch.usage
        end

        local file_path = shell:getAbsPath(args[1])
        local file
        local err
        if fs.exists(file_path) then
            file, err = fs.open (file_path, "a")
            if not file then
                return "Error: Unable to update timestamp: " .. err
            end
        else
            file, err = fs.open(file_path, "w")
            if not file then
                return "Error: Unable to create or update file: " .. err
            end
        end
        fs.close(file)

        return ""
    end

return touch