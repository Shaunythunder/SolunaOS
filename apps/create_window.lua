-- apps/create_window.lua_pattern

local window = require("window")
local colors = require("colors")

local create_window_app = {}
create_window_app.__index = create_window_app

function create_window_app.new(x_pos, y_pos, width, height, title, border_color, bg_color)
    local self = setmetatable({}, create_window_app)
    local h = _G.height
    local w = _G.width
    local window_x_pos = x_pos or 1
    local window_y_pos = y_pos or 1
    local window_width = width or 40
    local window_height = height or 20

    local window_border_color = border_color or colors.LIGHTGRAY
    local window_bg_color = bg_color or colors.DARKBLUE
    local window_title = title or "New Window"
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
    return self
end

return create_window_app