-- /lib/core/cursor.lua
-- Cursor management module

local os = require("os")
local gpu = _G.primary_gpu
local x_max_pos, y_max_pos = _G.width, _G.height
local x_min_pos, y_min_pos = 1, 1
local old_fg = gpu.getForeground()
local old_bg = gpu.getBackground()
local old_char = " "

local cursor = {}
    cursor.__index = cursor

    -- Creates a new cursor object
    function cursor.new()
        local self = setmetatable({}, cursor)
        self.x_pos = x_min_pos
        self.y_pos = y_min_pos
        self.home_y = y_min_pos
        self.x_max_pos = x_max_pos
        self.y_max_pos = y_max_pos
        self.x_min_pos = x_min_pos
        self.y_min_pos = y_min_pos
        self.old_char = old_char
        self.old_fg = old_fg
        self.old_bg = old_bg
        return self
    end

    -- Terminates the cursor and cleans it up
    function cursor:terminate()
        self:hide()
        for attribute in pairs(self) do
            self[attribute] = nil
        end
        setmetatable(self, nil)
        collectgarbage()
    end
    
    -- Resets the cursor to default
    function cursor:reset()
        self.x_pos = 1
        self.y_pos = 1
        self:updateBoundaries()
        self.x_min_pos = x_min_pos
        self.y_min_pos = y_min_pos
    end

    -- Update to screen boundaries
    function cursor:updateBoundaries()
        self.x_max_pos = _G.width
        self.y_max_pos = _G.height
    end

    --- Sets the position of the cursor.
    --- @param x_pos number
    --- @param y_pos number
    function cursor:setPosition(x_pos, y_pos)
        local height = _G.height
        local width = _G.width
        if self.x_max_pos > width then
            self.x_max_pos = width
        end
        if self.y_max_pos > height then
            self.y_max_pos = height
        end
        if x_pos < self.x_min_pos then
            self.x_pos = self.x_min_pos
        elseif x_pos > self.x_max_pos then
            self.x_pos = self.x_max_pos
        else
            self.x_pos = x_pos
        end
        if y_pos < self.y_min_pos then
            self.y_pos = self.y_min_pos
        elseif y_pos > self.y_max_pos then
            self.y_pos = self.y_max_pos
        else
            self.y_pos = y_pos
        end
    end

    -- Get the cursor x position
    function cursor:getX()
        return self.x_pos
    end

    -- Get the cursor y position
    function cursor:getY()
        return self.y_pos
    end

    -- Set the return y position of the cursor
    function cursor:setHomeY(y_home_pos)
        self.home_y = y_home_pos
    end

    -- Get return y position of the cursor
    function cursor:getHomeY()
        return self.home_y
    end

    -- Move the cursor position by a certain amount
    --- @param x_pos number
    --- @param y_pos number
    function cursor:movePosition(x_pos, y_pos)
        self:updateBoundaries()
        self.x_pos = self.x_pos + x_pos
        self.y_pos = self.y_pos + y_pos
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

    -- Show the cursor
    function cursor:show()
        self.old_char, self.old_fg, self.old_bg = gpu.get(self.x_pos, self.y_pos)
        gpu.setForeground(self.old_bg)
        gpu.setBackground(self.old_fg)
        gpu.set(self.x_pos, self.y_pos, self.old_char)
    end

    -- Hide the cursor
    function cursor:hide()
        gpu.setForeground(self.old_fg)
        gpu.setBackground(self.old_bg)
        gpu.set(self.x_pos, self.y_pos, self.old_char)
    end

return cursor