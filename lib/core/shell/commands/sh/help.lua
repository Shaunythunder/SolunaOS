-- /lib/core/shell/commands/sh/help.lua

local fs = require("filesystem")

local help = {}
help.description = "Displays help information about shell commands"
help.usage = "Usage: help [command]"
help.flags = {}

    function help.execute(args, flags, shell)
        if #args > 1 then
            return help.usage
        end

        local command_paths = {
        "/lib/core/shell/commands/filesystem",
        "/lib/core/shell/commands/navigation",
        "/lib/core/shell/commands/text",
        "/lib/core/shell/commands/system",
        "/lib/core/shell/commands/environment",
        "/lib/core/shell/commands/network",
        "/lib/core/shell/commands/sh",
        "/lib/core/shell/commands/misc",
       }

       local command_name
       if #args == 0 then
            local shell_commands = {}

            for _, path in ipairs(command_paths) do
                local full_module_path = path
                local commands = fs.list(full_module_path)
                if commands and fs.isDirectory(full_module_path) then
                    for _, command in ipairs(commands) do
                        local command_name = command:match("^(.*)%.lua$")
                        if command_name then
                            table.insert(shell_commands, command_name)
                        end
                    end
                    table.sort(shell_commands)
                end
            end
      
            local output = "Available commands:\n"
            for i, command in ipairs(shell_commands) do
                if i > 1 then
                    output = output .. " | " .. command
                else
                    output = output .. " " .. command
                end
            end
            return output
            
        elseif #args == 1 then
            command_name = args[1]
            for _, path in ipairs(command_paths) do
                local full_module_path = path .. "/" .. command_name
                local ok, command_module = pcall(require, full_module_path)
                if ok and command_module and command_module.execute then
                    print("Command Name: " .. command_name)
                    print("Module Path: " .. full_module_path)
                    if command_module.description then
                        print("Description: " .. command_module.description)
                    else
                        print("No description available.")
                    end
                    if command_module.usage then
                        print(command_module.usage)
                    else
                        print("No usage information available.")
                    end
                    if command_module.flags and next(command_module.flags) ~= nil then
                        print("Flags:")
                        for flag, desc in pairs(command_module.flags) do
                            print(" -" .. flag .. ": " .. desc)
                        end
                    else
                        print("No flags available.")
                    end
                    return ""
                end
            end
        end
        print("Command not found: " .. command_name)
        print("If custom command, please check module file for errors.")
    end

    return help