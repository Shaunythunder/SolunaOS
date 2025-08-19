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

local io = require("io")

_G._print_y = nil -- cleanup
_G.bootPrint = nil -- cleanup
--
_G.print = function(...)
    local args = {...}
    for i = 1, #args do
        args[i] = tostring(args[i])
    end
    io.write(table.unpack(args))
end

print("SolunaOS initializing...")

dofile("test/real_fstest.lua")
