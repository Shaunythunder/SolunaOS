

local Keyboard = require("keyboard")
local keyboard = Keyboard.new()
_G.keyboard = keyboard

local Event = dofile("lib/core/event/event.lua")
local event = Event.new()
_G.event = event



dofile("/lib/shell.lua")
