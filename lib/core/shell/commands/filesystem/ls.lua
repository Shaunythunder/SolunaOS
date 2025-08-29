-- lib/core/shell/commands/filesystem/ls.lua
local fs = require("filesystem")
local ls = {}

    -- This command lists the files in a directory.
    function ls.execute(args, input_data, shell)
        local directory
        if #args == 0 then
            directory = shell.current_dir
        elseif #args > 1 then
            return "Usage: ls or ls [directory]"
        else
            directory = shell:getAbsPath(args[1])
        end
        local files = fs.list(directory)
        local objects = {}
        if files and type(files) == "table" then
            for i, object in ipairs(files) do
                if object:sub(-1) == "/" then
                    object = object:sub(1, -2)
                    table.insert(objects, object)
                else
                    table.insert(objects, object)
                end
            end
            return table.concat(objects, " ")
        else
            return "Error: Unable to list directory " .. directory
        end
    end

return ls