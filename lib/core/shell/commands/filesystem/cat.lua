-- lib/core/shell/commands/filesystem/cat.lua

local fs = require("filesystem")

local cat = {}
cat.description = "Concatenate and display file content"
cat.usage = "Usage: cat <file>"
cat.flags = {}

    -- Does not display correctly. issue at display layer
    function cat.execute(args, _, shell)
        if #args == 0 then
            return cat.usage
        end

        local abs_path = shell:getAbsPath(args[1])

        if not fs.exists(abs_path) then
            return "Error: File does not exist: " .. abs_path
        end

        local file = fs.open(abs_path, "r")
        if not file then
            return "Error: Unable to open file: " .. abs_path
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