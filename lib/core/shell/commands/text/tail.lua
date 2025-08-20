-- lib/core/shell/commands/text/tail.lua

local fs = require("filesystem")
local tail = {}

    function tail.execute(args, input_data, shell)
        if #args == 0 then
            return "Usage: tail <file>"
        end

        local filename = args[1]
        local lines = args[2] and tonumber(args[2]) or 10

        if not fs.exists(filename) then
            return "Error: File does not exist: " .. filename
        end

        local file = fs.open(filename, "r")
        local content = fs.read(file)
        fs.close(file)

        local all_lines = {}
        for line in content:gmatch("[^\n]+") do
            table.insert(all_lines, line)
        end

        local start = math.max(1, #all_lines - lines + 1)
        local tail_result = {}
        for i = start, #all_lines do
            table.insert(tail_result, all_lines[i])
        end

        return table.concat(tail_result, "\n")
    end

    return tail