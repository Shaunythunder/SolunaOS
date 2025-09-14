-- lib/desktop/core/window/window_screen.lua

local window_screen = {}
window_screen.__index = window_screen

    function window_screen.new(window)
        local self = setmetatable({}, window_screen)
        self.window = window
        self.app = window.app
        self.x_pos = window.x_pos + 1
        self.y_pos = window.y_pos + 1
        self.width = window.width
        self.height = window.height
        return self
    end

    function window_screen:terminate()
        for attribute in pairs(self) do
            self[attribute] = nil
        end
        setmetatable(self, nil)
    end

    function window_screen:getDimensions()
        return self.x, self.y, self.width, self.height
    end

    function window_screen:setDimensions(width, height)
        self.width = width or self.width
        self.height = height or self.height
    end

    function window_screen:move(x_pos, y_pos)
        self.x_pos = x_pos
        self.y_pos = y_pos
    end