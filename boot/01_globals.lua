-- boot/01_globals.lua
-- Sets up global variables and settings

_G.width, _G.height = _G.primary_gpu.getResolution()
_G.display_available = true

_G.primary_gpu.fill(1, 1, width, height, " ") -- clear entire screen

local Component_manager = require("component")
local component_manager = Component_manager.new()
_G.component_manager = component_manager


_G.fps = 0.05

local Keyboard = require("keyboard")
local keyboard = Keyboard.new()
_G.keyboard = keyboard

local Cursor = require("cursor")
local cursor = Cursor.new()
_G.cursor = cursor

local Scroll_buffer = require("scroll_buffer")
local scroll_buffer = Scroll_buffer.new()
_G.scroll_buffer = scroll_buffer

local Event = require("event")
local event = Event.new()
_G.event = event


local terminal = require("terminal")


--_G._print_y = nil -- cleanup
--_G.bootPrint = nil -- cleanup

_G.print = function(...)
    local args = {...}
    local output = {}
    for _, arg in ipairs(args) do
        table.insert(output, tostring(arg))
    end
    terminal.writeBuffered(_G.scroll_buffer, table.concat(output, " "))
end

print("SolunaOS initializing...")





