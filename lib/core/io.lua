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

local io = {}

    function io.write(...)
        local args = {...}
        cursor:setHomeY(cursor:getY() + 1)
        cursor:setPosition(cursor:getX(), cursor:getY())
        local output = table.concat(args, " ")
        draw.termText(output)
    end

    function io.writeBuffered(scroll_buffer, ...)
        local args = {...}
        local output = table.concat(args, " ")
        scroll_buffer:addLine(output)
        
        local width, height = gpu.getResolution()
        local visible_lines = scroll_buffer:getVisibleLines()
        if #visible_lines >= height then
            draw.clear()
            for line = 1, height - 1 do
                if visible_lines[line + 1] then
                    draw.termText(visible_lines[line + 1], 1, line)
                end
            end
            draw.termText(output, 1, height)
        else
            draw.termText(output, 1, #visible_lines)
        end
        local cursor_y = math.min(#visible_lines + 1, height)
        cursor:setHomeY(cursor_y)
        cursor:setPosition(1, cursor_y)
        os.sleep(fps) -- Allow time for rendering
    end

    function io.read(prompt)
        local prepend_text = prompt or ""
        draw.termText(prepend_text, #prepend_text, cursor:getHomeY())
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
            draw.termText(string, 1, cursor:getHomeY())
            local cursor_x = #prepend_text + input_buffer:getPosition()
            cursor:setPosition(cursor_x, cursor:getHomeY())
        end
    end

return io