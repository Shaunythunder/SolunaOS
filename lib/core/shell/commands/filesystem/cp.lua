-- lib/core/shell/commands/filesystem/cp.lua

local fs = require("filesystem")

local cp = {}
cp.description = "Copy a file or directory"
cp.usage = "Usage: cp <source> <destination>"
cp.flags = {}

    -- Copies a file or directory
    function cp.execute(args, _, shell)
        if #args < 2 then
            return cp.usage
        end

        local source = shell:getAbsPath(args[1])
        local destination = shell:getAbsPath(args[2])

        if not fs.exists(source) then
            return "Error: Source file does not exist: " .. source
        end

        if fs.exists(destination) then
            return "Error: Destination already exists: " .. destination
        end

        local success, err = fs.copy(source, destination)
        if not success then
            return "Error: Unable to copy: " .. err
        end

        return ""
    end

return cp