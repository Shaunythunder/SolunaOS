-- /lib/core/shell/commands/navigation/pushd.lua

local fs = require("filesystem")
local pushd = {}
pushd.description = "Saves the current directory and changes to a new one"
pushd.usage = "Usage: pushd [directory]"
pushd.flags = {}

    -- This command saves the current directory and changes to a new one.
    function pushd.execute(args, input_data, shell)
        local target_dir
        if #args > 1 then
            return pushd.usage
        end
        
        if #args == 0 then
            target_dir = "/home"
        else
            target_dir = args[1] or "/"
        end
        if target_dir == ".." then
            if shell.current_dir ~= "/" then
                local characters_until_slash = 0
                for i = #shell.current_dir - 1, 1, -1 do
                    if shell.current_dir:sub(i, i) == "/" then
                        characters_until_slash = i
                        break
                    end
                end
                if characters_until_slash > 1 then
                    target_dir = shell.current_dir:sub(1, characters_until_slash - 1)
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

    local fs_addr, rel_path, structure = fs.resolveIfMount(target_dir)

    local exists = fs.exists(target_dir)
    local isDir = fs.isDirectory(target_dir)

    if exists and isDir then
        shell:saveDirectory()
        shell.current_dir = target_dir
        shell:updatePrompt(shell.current_dir)
        return ""
    else
        return "Directory not found: " .. target_dir
    end
end

return pushd