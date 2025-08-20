-- boot/01_globals.lua

_G.fps = 0.05
local os = require("os")
local Keyboard = require("keyboard")
local keyboard = Keyboard.new()
_G.keyboard = keyboard

local Event = require("event")
local event = Event.new()
_G.event = event

local Cursor = require("cursor")
local cursor = Cursor.new()
_G.cursor = cursor

local terminal = require("terminal")
local Shell = require("shell")

--_G._print_y = nil -- cleanup
--_G.bootPrint = nil -- cleanup
--
_G.print = function(...)
    local args = {...}
    for i = 1, #args do
        args[i] = tostring(args[i])
    end
    terminal.write(table.unpack(args))
end

local shell = Shell.new()


print("SolunaOS initializing...")

shell:run()




