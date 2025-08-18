_G.fps = 0.05

local Keyboard = require("keyboard")
local keyboard = Keyboard.new()
_G.keyboard = keyboard

local Event = require("event")
local event = Event.new()
_G.event = event

local Cursor = require("cursor")
local cursor = Cursor.new()
_G.cursor = cursor

local render = require("render")

_G._print_y = nil -- cleanup
_G.bootPrint = nil -- cleanup
--
_G.print = function (...)
    cursor:setHomeY(cursor:getY() + 1)
    cursor:setPosition(cursor:getX(), cursor:getY())
    local out = table.concat({...}, " ")
    render.termText(out)
end

print("SolunaOS initializing...")

dofile("test/real_fstest.lua")
