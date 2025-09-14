-- lib/core/shell/commands/navigation/cd.lua

local fs = require("filesystem")

local cd = {}
cd.description = "Changes the current directory"
cd.usage = "Usage: cd [directory]"
cd.flags = {}

-- This command changes the current directory of the shell.
function cd.execute(args, _, shell)
    if #args > 1 then
        return cd.usage
    end

    local target_dir
    if #args == 0 then
        target_dir = "/home"
    else
        target_dir = args[1] or "/"
    end
    if target_dir == ".." then
        if shell.current_dir ~= "/" then
            local chars_to_slash = 0
            for i = #shell.current_dir - 1, 1, -1 do
                if shell.current_dir:sub(i, i) == "/" then
                    chars_to_slash = i
                    break
                end
            end
            if chars_to_slash > 1 then
                target_dir = shell.current_dir:sub(1, chars_to_slash - 1)
            else
                target_dir = "/"
            end
        else
            return ""
        end
    elseif target_dir == "." then
        return ""
    end

    target_dir = shell:getAbsPath(target_dir)

    local exists = fs.exists(target_dir)
    local isDir = fs.isDirectory(target_dir)

    if exists and isDir then
        shell.current_dir = target_dir
        shell:updatePrompt(shell.current_dir)
        return ""
    else
        return "Directory not found: " .. target_dir
    end
end

return cd