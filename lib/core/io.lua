-- /lib/core/io.lua
-- This module provides functions for input and output operations.
local cursor = require("core.cursor")

local gpu = _G.primary_gpu
local display_cursor = cursor.new()

local io = {}

function io.write(input_str)
    for character in input_str:gmatch(".") do
        if character == "\n" then
            display_cursor:setPosition(1, display_cursor:getY() + 1)
        else
            display_cursor:hide()
            gpu.set(display_cursor:getX(), display_cursor:getY(), character)
            display_cursor:movePosition(1, 0)
            display_cursor:show()
        end
    end
end

function io.read()
    local input = ""
    while true do
        local event, char = event.pull
    end
    return ""
end

function io.clear()

end

return io