local io = require("io")
io.clear()
local prompt = "SolunaOS # "
local keyboard = _G.keyboard


while true do
    local line = prompt .. io.read(prompt)
    if not line then
        break
    end
end