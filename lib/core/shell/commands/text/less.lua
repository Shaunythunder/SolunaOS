-- lib/core/shell/commands/terminal/pager.lua

local pager = require("pager")

local less = {}
less.description = "Displays file contents one page at a time"
less.usage = "Usage: less <filename>"
less.flags = {}

    function less.execute(args, input_data, shell)
        if #args == 0 or #args > 1 then
            return less.usage
        end

        local target_file = args[1]

        target_file = shell:getAbsPath(target_file)
        local pager_instance = pager.new()

        pager_instance:run(target_file)

        return ""
    end

return less