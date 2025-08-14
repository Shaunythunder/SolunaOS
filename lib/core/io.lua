-- /lib/core/io.lua
-- This module provides functions for input and output operations.

local Cursor = require("cursor")
local text_buffer = require("text_buffer")

local event = _G.event
local keyboard = _G.keyboard
local gpu = _G.primary_gpu
local cursor = Cursor.new()

local ENTER = keyboard.keys.K_ENTER
local BACKSPACE = keyboard.keys.K_BACKSPACE.code
local TAB = keyboard.keys.K_TAB.code
local L_ARROW = keyboard.keys.K_LEFT_ARROW.code
local R_ARROW = keyboard.keys.K_RIGHT_ARROW.code

local BLACK = 0x000000
local WHITE = 0xFFFFFF

local io = {}

function io.write(input_str)
    local string_length = #input_str
    local lines = {}
    local width, _ = gpu.getResolution()
    gpu.setForeground(WHITE)
    gpu.setBackground(BLACK)
    while string_length > width do
        local line = input_str:sub(1, width)
        table.insert(lines, line)
        input_str = input_str:sub(width + 1)
        string_length = #input_str
    end
    table.insert(lines, input_str)
    for _, line in ipairs(lines) do
        gpu.fill(cursor:getX(), cursor:getY(), width, 1, " ")
        gpu.set(cursor:getX(), cursor:getY(), line)
        cursor:movePosition(0, 1)
    end
    local cursor_x = (string_length % width) + 1
    local cursor_y = cursor:getY()
    if string_length % width == 0 then
        cursor_y = cursor_y + 1
    end
    cursor:setPosition(cursor_x, cursor_y - 1)
end

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
            break
        elseif character == "\t" then
            input_buffer:insert("    ")
        elseif character == "\b" then
            input_buffer:backspace()
        else
            input_buffer:insert(character)
        end
        local string = prepend_text .. input_buffer:getText()
        cursor:setPosition(1, cursor:getHomeY())
        io.write(string)
    end
    cursor:hide()
    return input_buffer:getText()
end

function io.clear()
    local width, height = gpu.getResolution()
    gpu.fill(1, 1, width, height, " ")
    cursor:setPosition(1, 1)
end

return io