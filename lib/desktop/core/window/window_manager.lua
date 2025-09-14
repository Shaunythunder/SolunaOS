-- /lib/gui/core/window_manager.lua

local window_manager = {}
window_manager.__index = window_manager

    function window_manager.new()
        local self = setmetatable({}, window_manager)
        self.taskbar_manager = nil
        self.app_manager = nil
        self.windows = {}
        self.focused_window = nil
        self.dragged = {}
        self.dragging = false
        self.expanded = {}
        self.expanding = false
        return self
    end

    function window_manager:terminate()
        for _, window in ipairs(self.windows) do
            window:terminate()
        end
        for attribute in pairs(self) do
            self[attribute] = nil
        end
        setmetatable(self, nil)
    end

    function window_manager:setTaskbarManager(taskbar_manager)
        self.taskbar_manager = taskbar_manager
    end

    function window_manager:setAppManager(app_manager)
        self.app_manager = app_manager
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

    function window_manager:handleClick(event_type, x_pos, y_pos)
        if event_type == "touch" then
            local clicked_window = self:handleTouch(x_pos, y_pos)
            if clicked_window and clicked_window:isPointInTitleBar(x_pos, y_pos) then
                self:startDrag(clicked_window, x_pos, y_pos)
                self.dragging = true
            elseif clicked_window and clicked_window:isPointInsideExpand(x_pos, y_pos) then
                self:startExpansion(clicked_window, x_pos, y_pos)
                self.expanding = true
        end
        elseif event_type == "drag" and self.dragging then
            self:updateDrag(x_pos, y_pos)
        elseif event_type == "drag" and self.expanding then
            self:updateExpansion(x_pos, y_pos)
        elseif event_type == "drop" and self.dragging then
            self:stopDrag(x_pos, y_pos)
            self.dragging = false
        elseif event_type == "drop" and self.expanding then
            self:stopExpansion()
            self.expanding = false
        end
    end

    function window_manager:handleTouch(x_pos, y_pos)
        for i = #self.windows, 1, -1 do
            local window = self.windows[i]
            if window:isPointInsideClose(x_pos, y_pos) then
                self:remove(window)
                window:terminate()
                self.app_manager:closeApp(window.app)
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
        self.dragged = {
        window = window,
        offset_x = start_x - window.x,
        offset_y = start_y - window.y
    }
    end

    function window_manager:isWithinSnap(x_pos, y_pos)
        local w = _G.width
        local h = _G.height
        local x_snap = (x_pos <= 3) or (x_pos >= w - 2)
        local y_snap = y_pos == 1
        if x_snap or y_snap then
            return true
        end
        return false
    end


    function window_manager:updateDrag(x_pos, y_pos)
        local window = self.dragged.window
        local window_old_width = window.width
        if window then
            if window.mode ~= "normal" then
                window:setMode("normal")
                local ratio = window_old_width / window.width
                self.dragged.offset_x = math.floor(self.dragged.offset_x / ratio)
            end
            local new_x = x_pos - self.dragged.offset_x
            local new_y = y_pos - self.dragged.offset_y
            self.dragged.window:move(new_x, new_y)
            if self:isWithinSnap(x_pos, y_pos) then
                window:setBorderColor(window.border_highlight)
                return
            elseif window.border ~= window.border_nonhighlight then
                window:setBorderColor(window.border_nonhighlight)
            end
        end
    end

    function window_manager:stopDrag(x_pos, y_pos)
        local w = _G.width
        local window = self.dragged.window
        if window.border ~= window.border_nonhighlight then
            window:setBorderColor(window.border_nonhighlight)
        end
        if self.dragged.window then
            local touching_side, side = window:isBorderTouchingScreenSideEdge()
            local touching_top = window:isBorderTouchingScreenTopEdge()

            if touching_top and self:isWithinSnap(x_pos, y_pos) then
                window:setMode("maximized")
            elseif touching_side and self:isWithinSnap(x_pos, y_pos) then
                window:setMode("half_max", side)
            else
                window:setMode("normal")
            end
        end
        self.dragged = {}
    end

    function window_manager:startExpansion(window, start_x, start_y)
        self.expanded = {
        window = window,
        offset_x = start_x - (window.x + window.width - 1),
        offset_y = start_y - (window.y + window.height - 1)
    }
    end

    function window_manager:updateExpansion(x_pos, y_pos)
        local window = self.expanded.window
        if window then
            local new_width = (x_pos - self.expanded.offset_x) - window.x + 1
            local new_height = (y_pos - self.expanded.offset_y) - window.y + 1
            if new_width < 10 then
                new_width = 10
            end
            if new_height < 5 then
                new_height = 5 
            end
            window:resize(new_width, new_height)
        end
    end

    function window_manager:stopExpansion()
        self.expanded = {}
    end

return window_manager