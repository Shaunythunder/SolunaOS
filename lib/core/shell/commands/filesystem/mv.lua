-- lib/core/shell/commands/filesystem/mv.lua

local fs = require("filesystem")

local mv = {}
mv.description = "Moves a file or directory"
mv.usage = "Usage: mv <source> <destination>"
mv.flags = {}

    -- Moves a file or directory
    function mv.execute(args, input_data, shell)
        if #args < 2 then
            return mv.usage
        end

        local source = shell:getAbsPath(args[1])
        local destination = shell:getAbsPath(args[2])

        if not fs.exists(source) then
            return "Error: Source does not exist: " .. source
        end

        if fs.exists(destination) then
            return "Error: Destination already exists: " .. destination
        end

        local success, err = fs.move(source, destination)
        if not success then
            return "Error: Unable to move: " .. err
        end

        return ""
    end

return mv