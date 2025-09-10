--/lib/core/shell/commands/filesystem/edit.lua

local file_editor = require("file_editor")

local edit = {}
edit.description = "Opens a file in the text editor"
edit.usage = "Usage: edit <filename>"
edit.flags = {}

    function edit.execute(args, _, shell)
        if #args == 0 or #args > 1 then
            return edit.usage
        end

        local target_file = args[1]

        target_file = shell:getAbsPath(target_file)
        local editor = file_editor.new()

        editor:run(target_file)

        return ""
    end

return edit