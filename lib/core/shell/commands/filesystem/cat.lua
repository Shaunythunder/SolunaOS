-- lib/core/shell/commands/filesystem/cat.lua
local fs = require("filesystem")
local cat = {}

    -- Does not display correctly. issue at display layer
    function cat.execute(args, input_data, shell)
        if #args == 0 then
            return "Usage: cat <file>"
        end

        local filename = args[1]

        if not fs.exists(filename) then
            return "Error: File does not exist: " .. filename
        end

        local file = fs.open(filename, "r")
        if not file then
            return "Error: Unable to open file: " .. filename
        end

        local content = ""
        local chunk, err
        repeat
            chunk, err = fs.read(file, 4098)
            if chunk and chunk ~= "" then
                content = content .. chunk
            end
        until not chunk or chunk == "" or err

        fs.close(file)
        return content
    end

return cat