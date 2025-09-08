-- lib/core/shell/commands/text/echo.lua

local echo = {}
echo.description = "Displays a line of text"
echo.usage = "Usage: echo <text>"
echo.flags = {}

    function echo.execute(args, input_data, shell)
        if #args == 0 then
            return echo.usage
        end
        return table.concat(args, " ")
    end

return echo