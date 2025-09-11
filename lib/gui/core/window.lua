-- /lib/gui/core/window.lua

local drawgui = require("drawgui")
local unicode = require("unicode")

local window = {}
window.__index = window

    function window.new(x_pos, y_pos, win_width, win_height, bg_color, border_color, title)
        local self = setmetatable({}, window)
        self.x = x_pos
        self.y = y_pos
        self.width = win_width
        self.height = win_height
        self.saved_width = nil
        self.saved_height = nil
        self.bg = bg_color or 0x2D2D2D
        self.border = border_color or 0xCCCCCC
        self.title = title or nil
        self.focused_window = false
        self.mode = "normal" -- normal, minimized, maximized
        self:calcButtons()
        return self
    end

    function window:terminate()
        for attribute in pairs(self) do
            self[attribute] = nil -- Clear methods to free up memory
        end
        setmetatable(self, nil)
    end

    function window:move(new_x, new_y, mode)
        local mode = mode or "normal"
        if mode == "force" then
            self.x = new_x
            self.y = new_y
            self:calcButtons()
            return
        end
        local w = _G.width
        local h = _G.height
        local taskbar_offset = 2
        if new_x < 1 then
            new_x = 1
        end
        if new_y < 1 then
            new_y = 1
        end
        if new_x + self.width - 1 > w then
            new_x = w - self.width + 1
        end
        if new_y + taskbar_offset > h then
            new_y = h - taskbar_offset
        end
        self.x = new_x
        self.y = new_y
        self:calcButtons()
    end

    function window:resize(new_width, new_height)
        self.width = new_width
        self.height = new_height
        self:calcButtons()
    end
    
    function window:setMode(new_mode, side)
        if new_mode == "normal" or new_mode == "minimized" or new_mode == "maximized" or new_mode == "half_max" then
            self.mode = new_mode
        else
            error("Invalid mode. Use 'normal', 'minimized', 'maximized', or 'half_max'.")
        end
        self:handleMode(new_mode, side)
        self:calcButtons()
    end

    function window:handleMode(new_mode, side)
        local side = side or nil
        if new_mode == "normal" then
            if self.saved_width and self.saved_height then
                self:resize(self.saved_width, self.saved_height)
            end
            self.saved_height = nil
            self.saved_width = nil
            return
        elseif new_mode == "maximized" then
            self.saved_width = self.width
            self.saved_height = self.height
            self:resize(_G.width, _G.height - 2) -- Assuming taskbar height is 2
            self:move(1, 1)
            return
        elseif new_mode == "minimized" then
            self.saved_width = self.width
            self.saved_height = self.height
            self:resize(self.width, 1) -- Minimized to title bar height
            self:move(self.x, _G.height, "force") -- Move to bottom of screen
            return
        elseif new_mode == "half_max" then
            self.saved_width = self.width
            self.saved_height = self.height
            self:resize(math.floor(_G.width / 2), _G.height - 2) -- Half screen width, full height minus taskbar
            if side == "Left" then
                self:move(1, 1)
            elseif side == "Right" then
                self:move(math.floor(_G.width / 2) + 1, 1)
            end
        end
    end

    function window:setTitle(new_title)
        self.title = new_title
    end

    function window:setBackgroundColor(new_bg)
        self.bg = new_bg
    end

    function window:setBorderColor(new_border)
        self.border = new_border
    end

    function window:focused()
        self.focused_window = true
    end

    function window:unfocused()
        self.focused_window = false
    end

    function window:render()
        drawgui.renderWindow(self)
    end

    function window:calcButtons()
        local button_rack_y = self.y
        local button_spacing = 2
        local end_rack_x = self.x + self.width - 2

        self.close_button_x = end_rack_x
        self.close_button_y = button_rack_y
        self.close_button_symbol = unicode.CLOSE

        self.max_button_x = end_rack_x - button_spacing
        self.max_button_y = button_rack_y
        if self.mode == "maximized" then
            self.max_button_symbol = unicode.EXIT_FULLSCREEN
        else
            self.max_button_symbol = unicode.MAXIMIZE
        end

        self.min_button_x = self.max_button_x - button_spacing
        self.min_button_y = button_rack_y
        self.min_button_symbol = unicode.MINIMIZE
    end

    function window:isPointInsideClose(x_pos, y_pos)
        if x_pos == self.close_button_x and y_pos == self.close_button_y then
            return true
        end
        return false
    end

    function window:isPointInsideMax(x_pos, y_pos)
        if x_pos == self.max_button_x and y_pos == self.max_button_y then
            return true
        end
        return false
    end

    function window:isPointInsideMin(x_pos, y_pos)
        if x_pos == self.min_button_x and y_pos == self.min_button_y then
            return true
        end
        return false
    end

    function window:isPointInside(x_pos, y_pos)
        if x_pos >= self.x and x_pos <= (self.x + self.width - 1) and
           y_pos >= self.y and y_pos <= (self.y + self.height - 1) then
            return true
        end
        return false
    end

    function window:isPointInTitleBar(x_pos, y_pos)
        if self.title and y_pos == self.y and
           x_pos >= self.x and x_pos <= (self.x + self.width - 1) then
            return true
        end
        return false
    end

    function window:isBorderTouchingScreenSideEdge()
        local w = _G.width
        if self.x <= 1 then
            return true, "Left"
        elseif (self.x + self.width - 1) >= w then
            return true, "Right"
        end
        return false
    end

    function window:isBorderTouchingScreenTopEdge()
        if self.y <= 1 then
            return true
        end
        return false
    end

return window