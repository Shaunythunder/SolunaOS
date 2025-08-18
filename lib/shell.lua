local io = require("io")
local prompt = "SolunaOS # "
local keyboard = _G.keyboard


while true do
    io.write(prompt)
    local line = io.read()
    if not line then
        break
    end

    local cmd, args = line:match("^(%S+)%s*(.-)%s*$")
    if cmd == "exit" then
        break
    end
    if cmd then
        io.write("Command: " .. cmd .. "\n")
        if args then
            io.write("Arguments: " .. args .. "\n")
        end
    end
end