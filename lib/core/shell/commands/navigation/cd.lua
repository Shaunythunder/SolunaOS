-- lib/core/shell/commands/navigation/cd.lua
local fs = require("filesystem")
local shell = require("shell")
local cd = {}

    -- This command changes the current directory of the shell.
    function cd.execute(args, input_data, shell)
        local target_dir
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
        local fs_addr, rel_path = fs.resolveIfMount(target_dir)
        -- Direct component call to see if the filesystem works
        if fs.exists(target_dir) and fs.isDirectory(target_dir) then
            shell.current_dir = target_dir
            shell:updatePrompt(shell.current_dir)
            return ""
        else
            return "Directory not found: " .. target_dir
        end
    end

return cd