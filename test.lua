
local Keyboard = require("lib.core.keyboard")
local keyboard = Keyboard.new()
local keys = keyboard.keys -- ensure not nil

while true do
    local event, _, _, code = computer.pullSignal()
    if event == "key_down" then
        local key_entry
        for _, entry in pairs(keys) do
            if entry.code == code then
                key_entry = entry
                break
            end
        end

        if key_entry and key_entry.handler then
            local result = key_entry.handler(keyboard)
            print("Handler result:", tostring(result))
        elseif key_entry then
            print("Handler is nil for this key.")
        else
            print("No mapping for this key (code: 0x" .. string.format("%02X", code) .. ")")
        end
    end
end