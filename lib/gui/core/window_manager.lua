-- /lib/gui/core/window_manager.lua

local window_manager = {}
window_manager.__index = window_manager

    function window_manager.new()
        local self = setmetatable({}, window_manager)
        self.windows = {}
        self.focused_window = nil
        self.dragging = {}
        return self
    end

    function window_manager:add(window)
        table.insert(self.windows, window)
        if not self.focused_window then
            self.focused_window = window
        end
    end

    function window_manager:remove(window)
        for i, win in ipairs(self.windows) do
            if win == window then
                table.remove(self.windows, i)
                if self.focused_window == window then
                    self.focused_window = self.windows[#self.windows] or nil
                end
                return
            end
        end
    end

    function window_manager:renderAll()
        for _, window in ipairs(self.windows) do
            window:render()
        end
    end

    function window_manager:handleClick(x_pos, y_pos)
        for i = #self.windows, 1, -1 do
            local window = self.windows[i]
            if window:isPointInsideClose(x_pos, y_pos) then
                self:remove(window)
                window:terminate()
                return nil
            elseif window:isPointInsideMin(x_pos, y_pos) then
                window:setMode("minimized")
                return
            elseif window:isPointInsideMax(x_pos, y_pos) then
                if window.mode == "maximized" then
                    window:setMode("normal")
                else
                    window:setMode("maximized")
                end
                return
            elseif window:isPointInside(x_pos, y_pos) then
                self.focused_window = window
                window:focused()
                table.remove(self.windows, i)
                table.insert(self.windows, window)
                return window
            end
        end
    end

    function window_manager:startDrag(window, start_x, start_y)
        self.dragging = {
        window = window,
        mouse_start_x = start_x,
        mouse_start_y = start_y,
        offset_x = start_x - window.x,
        offset_y = start_y - window.y
    }
    end

    function window_manager:updateDrag(x_pos, y_pos)
        local window = self.dragging.window
        local window_old_width = window.width
        if window then
            if window.mode ~= "normal" then
                window:setMode("normal")
                local ratio = window_old_width / window.width
                self.dragging.offset_x = math.floor(self.dragging.offset_x / ratio)
            end
            local new_x = x_pos - self.dragging.offset_x
            local new_y = y_pos - self.dragging.offset_y
            self.dragging.window:move(new_x, new_y)
        end
    end

    function window_manager:stopDrag()
        if self.dragging.window then
            local window = self.dragging.window
            local touching_side, side = window:isBorderTouchingScreenSideEdge()
            local touching_top = window:isBorderTouchingScreenTopEdge()
            if touching_side then
                window:setMode("half_max", side)
            elseif touching_top then
                window:setMode("maximized")
            else
                window:setMode("normal")
            end
        end
        self.dragging = {}
    end


return window_manager