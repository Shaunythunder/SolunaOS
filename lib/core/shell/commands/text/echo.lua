-- lib/core/shell/commands/text/echo.lua

local echo = {}

function echo.execute(args, input_data, shell)
    if #args == 0 then
        return "Usage: echo <text>"
    end
    return table.concat(args, " ")
end

return echo