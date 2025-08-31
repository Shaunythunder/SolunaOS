--/lib/core/shell/commands/text/edit.lua
local file_editor = require("file_editor")

local edit = {}

    function edit.execute(args, input_data, shell)
        if #args == 0 or #args > 1 then
            return "Usage: edit <filename>"
        end

        local target_file = args[1]

        target_file = shell:getAbsPath(target_file)
        local editor = file_editor.new()

        editor:run(target_file)

        return ""
    end

return edit