-- lib/core/shell/commands/filesystem/rm.lua
local fs = require("filesystem")

local rm = {}

    -- Removes a file or directory
    function rm.execute(args, input_data, shell)
        if #args == 0 then
            return "Usage: rm <file>"
        end

        local filename = shell:getAbsPath(args[1])

        if not fs.exists(filename) then
            return "Error: File does not exist: " .. filename
        end

        local success, err = fs.remove(filename)
        if not success then
            return "Error: Unable to remove file: " .. err
        end

        return ""
    end

return rm