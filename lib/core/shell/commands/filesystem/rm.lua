-- lib/core/shell/commands/filesystem/rm.lua

local fs = require("filesystem")

local rm = {}
rm.description = "Removes a file or directory"
rm.usage = "Usage: rm [flags] <file>"
rm.flags = {
    f = "Force removal",
    r = "Remove directories and their contents recursively"
}

    -- Removes a file or directory
    function rm.execute(args, _, shell)
        if #args == 0 then
            print(rm.usage)
            for flag in pairs(rm.flags) do
                print(string.format("-" .. flag .. ": " .. rm.flags[flag]))
            end
            return ""
        end

        local force = false
        local recursive = false
        local targets = {}

        for _,arg in ipairs(args) do
            if arg:sub(1,1) == "-" then
                if arg == "-f" then
                    force = true
                elseif arg == "-r" then
                    recursive = true
                elseif arg == "-rf" or arg == "-fr" then
                    force = true
                    recursive = true
                end
            else
                table.insert(targets, arg)
            end
        end

        if #targets == 0 then
            print(rm.usage)
            for flag in pairs(rm.flags) do
                print(string.format("-" .. flag .. ": " .. rm.flags[flag]))
            end
            return ""
        end

        local file_path = shell:getAbsPath(targets[1])

        if not fs.exists(file_path) then
            if force then
                return ""
            else
                return "Error: File does not exist: " .. file_path
            end
        end

        if recursive then
            local success, err = fs.removeRecursive(file_path)
            if not success then
                return "Error: Unable to remove directory: " .. err
            end
        else
            local success, err = fs.remove(file_path)
            if not success then
                return "Error: Unable to remove file: " .. err
            end
        end



        return ""
    end

return rm