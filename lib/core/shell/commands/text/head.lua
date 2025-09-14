-- lib/core/shell/commands/text/head.lua

local fs = require("filesystem")

local head = {}
head.description = "Displays the first lines of a file"
head.usage = "Usage: head <file> [lines]"
head.flags = {}

function head.execute(args, _, _)
    if #args == 0 then
        return head.usage
    end

    local filename = args[1]
    local lines = args[2] and tonumber(args[2]) or 10

    if not fs.exists(filename) then
        return "Error: File does not exist: " .. filename
    end

    local file = fs.open(filename, "r")
    local content = fs.read(file)
    fs.close(file)
    local result = {}
    local count = 0

    for line in content:gmatch("[^\n]+") do
        if count < lines then
            table.insert(result, line)
            count = count + 1
        else
            break
        end
    end

    return table.concat(result, "\n")
end

    return head