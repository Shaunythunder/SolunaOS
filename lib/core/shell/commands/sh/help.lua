-- /lib/core/shell/commands/sh/help.lua

local fs = require("filesystem")

local help = {}
help.description = "Displays help information about shell commands"
help.usage = "Usage: help [command]"
help.flags = {}

    local CMD_PATHS = {
        "/lib/core/shell/commands/filesystem",
        "/lib/core/shell/commands/navigation",
        "/lib/core/shell/commands/text",
        "/lib/core/shell/commands/system",
        "/lib/core/shell/commands/environment",
        "/lib/core/shell/commands/network",
        "/lib/core/shell/commands/sh",
        "/lib/core/shell/commands/misc",
       }

    function help.execute(args, flags, shell)
        if #args > 1 then
            return help.usage
        end

       local cmd_name
       if #args == 0 then
            local shell_cmds = {}

            for _, path in ipairs(CMD_PATHS) do
                local full_module_path = path
                local cmds = fs.list(full_module_path)
                if cmds and fs.isDirectory(full_module_path) then
                    for _, cmd in ipairs(cmds) do
                        local cmd_name = cmd:match("^(.*)%.lua$")
                        if cmd_name then
                            table.insert(shell_cmds, cmd_name)
                        end
                    end
                    table.sort(shell_cmds)
                end
            end
      
            local output = "Available commands:\n"
            for i, cmd in ipairs(shell_cmds) do
                if i > 1 then
                    output = output .. " | " .. cmd
                else
                    output = output .. " " .. cmd
                end
            end
            return output
            
        elseif #args == 1 then
            cmd_name = args[1]
            for _, path in ipairs(CMD_PATHS) do
                local full_mod_path = path .. "/" .. cmd_name
                local ok, cmd_mod = pcall(require, full_mod_path)
                if ok and cmd_mod and cmd_mod.execute then
                    print("Command Name: " .. cmd_name)
                    print("Module Path: " .. full_mod_path)
                    if cmd_mod.description then
                        print("Description: " .. cmd_mod.description)
                    else
                        print("No description available.")
                    end
                    if cmd_mod.usage then
                        print(cmd_mod.usage)
                    else
                        print("No usage information available.")
                    end
                    if cmd_mod.flags and next(cmd_mod.flags) ~= nil then
                        print("Flags:")
                        for flag, desc in pairs(cmd_mod.flags) do
                            print(" -" .. flag .. ": " .. desc)
                        end
                    else
                        print("No flags available.")
                    end
                    return ""
                end
            end
        end
        print("Command not found: " .. cmd_name)
        print("If custom command, please check module file for errors.")
    end

    return help