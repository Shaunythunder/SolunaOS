-- lib/core/shell/commands/sh/shhist.lua

local pager = require("pager")

local shhist = {}
shhist.description = "Displays the shell command history"
shhist.usage = "Usage: shhist"
shhist.flags = {}

function shhist.execute(args, _, shell)
    if #args ~= 0 then
        return shhist.usage
    end

    local scroll_buffer = shell.scroll_buffer

    local target_file = scroll_buffer.log_file_path

    target_file = shell:getAbsPath(target_file)
    local pager_instance = pager.new()

    pager_instance:run(target_file)

    return ""
end

return shhist