-- /lib/core/io.lua
-- This module provides functions for input and output operations.

local cursor = _G.cursor
local text_buffer = require("text_buffer")

local event = _G.event
local keyboard = _G.keyboard
local gpu = _G.primary_gpu
local BLACK = 0x000000
local WHITE = 0xFFFFFF

local io = {}

    function io.calcWrap(prepend_text, string)
        local string_index = 1 + #prepend_text
        local wrap_index = 1
        local width, _ = gpu.getResolution()
        for character in string:gmatch(".") do
            string_index = string_index + 1
            if string_index > width then
                string_index = 1
                wrap_index = wrap_index + 1
            end
        end
        return wrap_index
    end

    function io.liveRender(input_str)
        local width, _ = gpu.getResolution()
        gpu.setForeground(WHITE)
        gpu.setBackground(BLACK)
        
        local lines = {}
        for newline in tostring(input_str):gmatch("([^\n]*)\n?") do
            table.insert(lines, newline)
        end

        local cursor_y = cursor:getY()
        local last_x = 1
        local last_y = cursor_y

        for i, line_text in ipairs(lines) do
            local string_length = #line_text
            while string_length > width do
                local line = line_text:sub(1, width)
                gpu.fill(1, last_y, width, 1, " ")
                gpu.set(1, last_y, line)
                cursor:movePosition(0, 1)
                cursor_y = cursor_y + 1
                line_text = line_text:sub(width + 1)
                string_length = #line_text
            end
            gpu.fill(1, cursor_y, width, 1, " ")
            gpu.set(1, cursor_y, line_text)
            last_x = (#line_text % width) + 1
            last_y = cursor_y
            cursor_y = cursor_y + 1
        end
        cursor:setPosition(last_x, last_y)
    end

    function io.write(input_str)
        io.liveRender(input_str)
        cursor:setHomeY(cursor:getY())
        local home_y = cursor:getHomeY()
        cursor:setPosition(1, home_y)
    end

    function io.read(prompt)
        local prepend_text = prompt or ""
        io.write(prepend_text)
        local input_buffer = text_buffer.new()
        while true do
            local character = nil
            while character == nil do
                cursor:show()
                character = event:keyboardListen(0.5)
                if character ~= nil then
                    break
                end
                cursor:hide()
                character = event:keyboardListen(0.5)
                if character ~= nil then
                    break
                end
            end
            if character == "\n" then
                cursor:hide()
                local wraps = io.calcWrap(prepend_text, input_buffer:getText())
                local new_y = cursor:getHomeY()
                if wraps > 0 then
                    new_y = cursor:getHomeY() + wraps
                else
                    new_y = cursor:getHomeY() + 1
                end
                cursor:setHomeY(new_y)
                cursor:setPosition(1, new_y)
                local string = prepend_text .. input_buffer:getText()
                io.write(string)
                break
            elseif character == "\t" then
                input_buffer:insert("    ")
            elseif character == "\b" then
                input_buffer:backspace()
            elseif character == "del" then
                input_buffer:delete()
            elseif character == "<-" then
                input_buffer:moveLeft()
                cursor:setPosition(input_buffer:getPosition(), cursor:getHomeY())
            elseif character == "->" then
                input_buffer:moveRight()
                cursor:setPosition(input_buffer:getPosition(), cursor:getHomeY())
            elseif #character == 1 then
                input_buffer:insert(character)
            end
            local string = prepend_text .. input_buffer:getText()
            cursor:setPosition(1, cursor:getHomeY())
            io.liveRender(string)
        end
    end

    function io.clear()
        local width, height = gpu.getResolution()
        gpu.fill(1, 1, width, height, " ")
        cursor:setPosition(1, 1)
    end

return io