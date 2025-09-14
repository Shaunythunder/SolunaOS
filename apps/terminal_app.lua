-- apps/create_window.lua_pattern

local window = require("window")
local colors = require("colors")
local shell = require("shell")
local cursor = require("cursor")
local scroll_buffer = require("scroll_buffer")

local terminal_app = {}
terminal_app.__index = terminal_app

    function terminal_app.new(x_pos, y_pos, width, height, title, border_color, bg_color)
        local self = setmetatable({}, terminal_app)
        local window_x_pos = x_pos or 1
        local window_y_pos = y_pos or 1
        local window_width = width or 40
        local window_height = height or 20

        local window_border_color = border_color or colors.LIGHTGRAY
        local window_bg_color = bg_color or colors.DARKBLUE
        local window_title = title or "Command Terminal"
        self.window = window.new(
                    window_x_pos,
                    window_y_pos,
                    window_width,
                    window_height,
                    window_bg_color,
                    window_border_color,
                    window_title
                )
        self.screen = self.window:getScreen()
        self.cursor = cursor.new()
        self.scroll_buffer = scroll_buffer.new()
        return self
    end

    function terminal_app:terminate()
        if self.window and self.window.terminate then
            self.window:terminate()
        end
        for attribute in pairs(self) do
            self[attribute] = nil -- Clear methods to free up memory
        end
        setmetatable(self, nil)
    end

    function terminal_app:run()
        shell.run()
    end


return terminal_app