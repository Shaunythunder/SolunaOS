-- /lib/terminal_apps/pager.lua
local fs = require("filesystem")
local pager_buffer = require("scroll_buffer")
local event = _G.event
local draw = require("draw")

local help_text = "Q: Quit | Up/Down Arrow Keys: Up/Down One Line | PGUP/PGDN: Up/Down One Page | Home: Top of Pager | End: End of Pager"

local pager = {}
pager.__index = pager

-- Creates a new pager instance
--- @param cursor table|nil
function pager.new(cursor)
    local self = setmetatable({}, pager)
    self.cursor = cursor or _G.cursor
    self.pager_buffer = pager_buffer.new()
    self.cursor:setPosition(-1, -1)
    return self
end

-- Cleans up the pager instance
function pager:terminate()
    self.pager_buffer:terminate()
    for attribute in pairs(self) do
        self[attribute] = nil
    end
    setmetatable(self, nil)
end

-- Main run loop for the pager
--- @param filepath string
--- @param mode string|nil "start" or "end"
function pager:run(filepath, mode)
    if mode == nil or (mode ~= "start" and mode ~= "end") then
        mode = "start"
    end

    self.cursor:setNotVisible()
    local filename = fs.getNameFromPath(filepath)
    self.pager_buffer.filepath = filepath
    self.pager_buffer.filename = filename
    draw.clear()
    if fs.exists(filepath) then
        self.pager_buffer:loadFromFile(filepath)
        self.pager_buffer:renderBottomLine(help_text)
    end

    self:pager()
    self:terminate()
    draw.clear()
    self.cursor:setVisible()
end

-- Handles user input for the pager
    --- @return string character
function pager:input()
    local char
    local output
    while char == nil do
        output = event:listen(0.5)
        if output ~= nil and type(output) == "string" then
            char = output
            break
        end
        output = event:listen(0.5)
        if output ~= nil and type(output) == "string" then
            char = output
            break
        end
    end
    return char
end

-- Main pager functionality loop
function pager:pager()
    while true do
        local char = self:input()
        if char == "\\^" then
            self.pager_buffer:lineUp()
        elseif char == "\\v" then
            self.pager_buffer:lineDown()
        elseif char == "pgup" then
            self.pager_buffer:pageUp()
        elseif char == "pgdn" then
            self.pager_buffer:pageDown()
        elseif char == "home" then
            self.pager_buffer:goToStart()
        elseif char == "end" then
            self.pager_buffer:goToEnd()
        elseif char == "q" then
            break
        end
    end
end

return pager