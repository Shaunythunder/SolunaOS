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

local io = {}



function io.write(input_str)
    local string_index = 1
    local width, _ = gpu.getResolution()
    for character in input_str:gmatch(".") do
        gpu.set(cursor:getX(), cursor:getY(), character)
        cursor:movePosition(1, 0)
        string_index = string_index + 1
        if string_index > width then
            string_index = 1
            cursor:setPosition(1, cursor:getY() + 1)
        end
    end
    cursor:hide()
end

function io.redrawInput(prepend_text, input_buffer)
    local y_pos = cursor:getY()
    local width, _ = gpu.getResolution()
    gpu.fill(cursor:getX(), cursor:getY(), width, 1, " ")
    cursor:setPosition(1, y_pos)
    io.write(prepend_text)
    cursor:setPosition(#prepend_text + 1, y_pos)
    io.write(input_buffer:getText())
    cursor:setPosition(#prepend_text + input_buffer:getPosition(), y_pos)
    cursor:show()
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
            cursor:setPosition(cursor:getX(), cursor:getY() + 1)
            break
        elseif character == "\t" then
            input_buffer:insert("    ")
        elseif character == "\b" then
            input_buffer:backspace()
        else
            input_buffer:insert(character)
        end
        io.redrawInput(prepend_text, input_buffer)
    end
    cursor:show()
    return input_buffer:getText()
end

function io.clear()
    local width, height = gpu.getResolution()
    gpu.fill(1, 1, width, height, " ")
    cursor:setPosition(1, 1)
end

return io