-- lib/core/shell/commands/terminal/pager.lua

local pager = require("pager")

local pager_command = {}

    function pager_command.execute(args, input_data, shell)
        if #args == 0 or #args > 1 then
            return "Usage: pager <filename>"
        end

        local target_file = args[1]

        target_file = shell:getAbsPath(target_file)
        local pager_instance = pager.new()

        pager_instance:run(target_file)

        return ""
    end

return pager_command