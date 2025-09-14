-- lib/core/shell/commands/filesystem/ls.lua

local fs = require("filesystem")

local ls = {}
ls.description = "Lists files in a directory"
ls.usage = "Usage: ls [directory]"
ls.flags = {}

-- This command lists the files in a directory.
function ls.execute(args, _, shell)
    local dir
    if #args == 0 then
        dir = shell.current_dir
    elseif #args > 1 then
        return ls.usage
    else
        dir = shell:getAbsPath(args[1])
    end
    local files = fs.list(dir)
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
        return "Error: Unable to list directory " .. dir
    end
end

return ls