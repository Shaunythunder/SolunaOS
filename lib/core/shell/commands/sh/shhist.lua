-- lib/core/shell/commands/sh/shhist.lua

local pager = require("pager")
local scroll_buffer = _G.scroll_buffer

local shhist = {}
    function shhist.execute(args, input_data, shell)
        if #args ~= 0 then
            return "Usage: shhist"
        end

        local target_file = scroll_buffer.log_file_path

        target_file = shell:getAbsPath(target_file)
        local pager_instance = pager.new()

        pager_instance:run(target_file)

        return ""
    end

return shhist