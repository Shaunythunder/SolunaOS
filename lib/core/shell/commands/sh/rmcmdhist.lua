-- /lib/core/shell/commands/sh/rmcmdhist.lua

local fs = require("filesystem")

local rmcmdhist = {}
rmcmdhist.description = "Removes the command history"
rmcmdhist.usage = "Usage: rmcmdhist"
rmcmdhist.flags = {}

    -- Removes the shell command history log file
    function rmcmdhist.execute(args, input_data, shell)
        if #args ~= 0 then
            return rmcmdhist.usage
        end

        local command_history_path = "/etc/logs/command_history.log"
        local abs_path = shell:getAbsPath(command_history_path)

        if not fs.exists(abs_path) then
            return "Error: Command history file does not exist: " .. abs_path
        end

        local success, err = fs.remove(abs_path)
        if not success then
            return "Error: Unable to remove command history file: " .. err
        end

        -- Clear in-memory history as well
        shell.command_history = {}
        shell:resetHistoryIndex()

        return ""
    end

return rmcmdhist