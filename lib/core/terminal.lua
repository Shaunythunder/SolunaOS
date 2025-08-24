-- /lib/core/io.lua
-- This module provides functions for input and output operations.

local cursor = _G.cursor
local fps = _G.fps
local text_buffer = require("text_buffer")
local os = require("os")
local draw = require("draw")
local event = _G.event
local keyboard = _G.keyboard
local gpu = _G.primary_gpu
local BLACK = 0x000000
local WHITE = 0xFFFFFF

local terminal = {}

    function terminal.write(...)
        local args = {...}
        local output = table.concat(args, " ")
        local increment = draw.termText(output, 1)
        cursor:setHomeY(cursor:getHomeY() + increment)
        cursor:setPosition(1, cursor:getHomeY())
    end

    function terminal.writeBuffered(scroll_buffer, ...)
        local args = {...}
        local height = _G.height
        local output = table.concat(args, " ")
        local increment = scroll_buffer:addLine(output)
        
        local visible_lines = scroll_buffer:getVisibleLines()
        local cursor_y = math.min(#visible_lines, height) + increment
        if cursor_y > height then
            cursor_y = height
        end
        scroll_buffer:pushReset()
        cursor:setHomeY(cursor_y)
        cursor:setPosition(1, cursor_y)
    end

    function terminal.read(prompt)
        local prepend_text = prompt or ""
        draw.termText(prepend_text, #prepend_text)
        cursor:setPosition(#prepend_text + 1, cursor:getHomeY())
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
                local string = input_buffer:getText()
                return string
            elseif character == "\t" then
                input_buffer:insert("    ")
            elseif character == "\b" then
                input_buffer:backspace()
            elseif character == "del" then
                input_buffer:delete()
            elseif character == "<-" then
                input_buffer:moveLeft()
            elseif character == "->" then
                input_buffer:moveRight()
            elseif #character == 1 then
                input_buffer:insert(character)
            end
            local string = prepend_text .. input_buffer:getText()
            draw.termText(string, 1)
            local cursor_x = (#prepend_text + input_buffer:getPosition()) % width
            local cursor_y = cursor:getHomeY() + math.floor((#prepend_text + input_buffer:getPosition() - 1) / width)
            cursor:setPosition(cursor_x, cursor_y)
        end
    end

return terminal