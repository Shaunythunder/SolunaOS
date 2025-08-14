-- /lib/core/cursor.lua
-- Cursor management module

local os = require("os")
local gpu = _G.primary_gpu
local x_max_pos, y_max_pos = gpu.getResolution()
local x_min_pos, y_min_pos = 1, 1 -- Also default position
local old_foreground = gpu.getForeground()
local old_background = gpu.getBackground()
local old_character = " "

local cursor = {}
cursor.__index = cursor

function cursor.new()
    local self = setmetatable({}, cursor)
    self.x_pos = x_min_pos
    self.y_pos = y_min_pos
    self.home_y = y_min_pos
    self.x_max_pos = x_max_pos
    self.y_max_pos = y_max_pos
    self.x_min_pos = x_min_pos
    self.y_min_pos = y_min_pos
    self.saved_x = nil
    self.saved_y = nil
    self.old_character = old_character
    self.old_foreground = old_foreground
    self.old_background = old_background
    return self
end

function cursor:terminate()
    self:hide()
    for attribute in pairs(self) do
        self[attribute] = nil -- Clear methods to free up memory
    end
    setmetatable(self, nil)
    collectgarbage()
end

function cursor:reset()
    self.x_pos = 1
    self.y_pos = 1
    self:updateBoundaries() -- self.x_max_pos, self.y_max_pos
    self.x_min_pos = x_min_pos
    self.y_min_pos = y_min_pos
end

function cursor:updateBoundaries()
    self.x_max_pos, self.y_max_pos = gpu.getResolution()
end

function cursor:getMinX()
    return self.x_min_pos
end

function cursor:getMinY()
    return self.y_min_pos
end

function cursor:setMinY(y_min_pos)
    self.y_min_pos = y_min_pos
end

function cursor:getMaxX()
    return self.x_max_pos
end

function cursor:setMaxX(x_max_pos)
    self.x_max_pos = x_max_pos
end

function cursor:getMaxY()
    return self.y_max_pos
end

function cursor:setPosition(x_set_pos, y_set_pos)
    local screen_width, screen_height = gpu.getResolution()
    if self.x_max_pos > screen_width then
        self.x_max_pos = screen_width
    end
    if self.y_max_pos > screen_height then
        self.y_max_pos = screen_height
    end
    if x_set_pos < self.x_min_pos then
        self.x_pos = self.x_min_pos
    elseif x_set_pos > self.x_max_pos then
        self.x_pos = self.x_max_pos
    else
        self.x_pos = x_set_pos
    end
    if y_set_pos < self.y_min_pos then
        self.y_pos = self.y_min_pos
    elseif y_set_pos > self.y_max_pos then
        self.y_pos = self.y_max_pos
    else
        self.y_pos = y_set_pos
    end
end

function cursor:getPosition()
    return self.x_pos, self.y_pos
end

function cursor:getX()
    return self.x_pos
end

function cursor:setHomeY(y_home_pos)
    self.home_y = y_home_pos
end

function cursor:getHomeY()
    return self.home_y
end

function cursor:getY()
    return self.y_pos
end

function cursor:getBoundaries()
    return self.x_min_pos, self.y_min_pos, self.x_max_pos, self.y_max_pos
end

function cursor:movePosition(move_x_pos, move_y_pos)
    self:updateBoundaries()
    self.x_pos = self.x_pos + move_x_pos
    self.y_pos = self.y_pos + move_y_pos
    if self.x_pos > self.x_max_pos then
        self.x_pos = self.x_min_pos
        self.y_pos = self.y_pos + 1 -- Wrap to next line
    elseif self.x_pos < self.x_min_pos then
        self.x_pos = self.x_min_pos
    end
    if self.y_pos < self.y_min_pos then
        self.y_pos = self.y_min_pos
    elseif self.y_pos > self.y_max_pos then
        self.y_pos = self.y_max_pos
    end
end

function cursor:show()
    self.old_character, self.old_foreground, self.old_background = gpu.get(self.x_pos, self.y_pos)
    gpu.setForeground(self.old_background)
    gpu.setBackground(self.old_foreground)
    gpu.set(self.x_pos, self.y_pos, self.old_character)
end

function cursor:hide()
    gpu.setForeground(self.old_foreground)
    gpu.setBackground(self.old_background)
    gpu.set(self.x_pos, self.y_pos, self.old_character)
end


function cursor:save()
    self.saved_x = self.x_pos
    self.saved_y = self.y_pos
end

function cursor:restore()
    if self.saved_x == nil or self.saved_y == nil then
        return
    else
        self.x_pos = self.saved_x
        self.y_pos = self.saved_y
    end
end

return cursor