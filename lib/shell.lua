local io = require("io")
io.clear()
local prompt = "SolunaOS # "

while true do
    local line = prompt .. io.read(prompt)
    if not line then
        break
    else print(line)
    end
end