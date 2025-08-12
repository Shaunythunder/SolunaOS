local os = require("os")
local key_map = require("keyboard_map") 


local buffer = ""
local cursor_pos = 1
local y_pos = 1
local x_pos = 1
local min_x, min_y = 1, 1
local max_x, max_y = 80, 25  -- adjust based on your display

while true do
    local _, _, _, code = os.pullSignal("key_down")
    local handler = key_map[code]
    local result


    if handler then
    
        result = handler(buffer, cursor_pos) or handler(y_pos, min_y) or handler(x_pos, min_x)
    end

    print(string.format("Key code: 0x%02X", code))
    if result then
        print("Result:", tostring(result))
    elseif handler then
        print("Handler ran, no printable result.")
    else
        print("No mapping for this key.")
    end
end