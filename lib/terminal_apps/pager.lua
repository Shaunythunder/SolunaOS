-- /lib/terminal_apps/pager.lua
local fs = require("filesystem")
local pager_buffer = require("scroll_buffer")
local event = _G.event
local cursor = _G.cursor
local draw = require("draw")

local help_text = "Q: Quit | Up/Down Arrow Keys: Up/Down One Line | PGUP/PGDN: Up/Down One Page | Home: Top of Pager | End: End of Pager"

local pager = {}
    pager.__index = pager

    function pager.new()
        local self = setmetatable({}, pager)
        self.pager_buffer = pager_buffer.new()
        cursor:setPosition(-1, -1)
        return self
    end

    function pager:terminate()
        self.pager_buffer:terminate()
        for attribute in pairs(self) do
            self[attribute] = nil -- Clear methods to free up memory
        end
        setmetatable(self, nil)
    end

    function pager:run(filepath, mode)
        if mode == nil or (mode ~= "start" and mode ~= "end") then
            mode = "start"
        end

        cursor:setNotVisible()
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
        cursor:setVisible()
    end

    function pager:input()
        local character
        local output
        while character == nil do
            output = event:listen(0.5)
            if output ~= nil and type(output) == "string" then
                character = output
                break
            end
            output = event:listen(0.5)
            if output ~= nil and type(output) == "string" then
                character = output
                break
            end
        end
        return character
    end

    function pager:pager()
        while true do
            local character = self:input()
            if character == "\\^" then
                self.pager_buffer:lineUp()
            elseif character == "\\v" then
                self.pager_buffer:lineDown()
            elseif character == "pgup" then
                self.pager_buffer:pageUp()
            elseif character == "pgdn" then
                self.pager_buffer:pageDown()
            elseif character == "home" then
                self.pager_buffer:goToStart()
            elseif character == "end" then
                self.pager_buffer:goToEnd()
            elseif character == "q" then
                break
            end
        end
    end

return pager