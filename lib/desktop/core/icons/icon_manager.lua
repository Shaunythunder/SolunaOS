-- /lib/desktop/core/icons/icon_manager.lua

local icon_manager = {}
icon_manager.__index = icon_manager

    function icon_manager.new()
        local self = setmetatable({}, icon_manager)
        self.taskbar_manager = nil
        self.app_manager = nil
        self.icons = {}
        self.dragged = {}
        self.dragging = false
        return self
    end

    function icon_manager:terminate()
        for _, icon in ipairs(self.icons) do
            icon:terminate()
        end
        for attribute in pairs(self) do
            self[attribute] = nil
        end
        setmetatable(self, nil)
    end

    function icon_manager:setTaskbarManager(taskbar_manager)
        self.taskbar_manager = taskbar_manager
    end

    function icon_manager:setAppManager(app_manager)
        self.app_manager = app_manager
    end

    function icon_manager:add(icon)
        table.insert(self.icons, icon)
    end

    function icon_manager:remove(icon_to_remove)
        for i, icon in ipairs(self.icons) do
            if icon == icon_to_remove then
                table.remove(self.icons, i)
                return
            end
        end
    end

    function icon_manager:renderAll()
        for _, icon in ipairs(self.icons) do
            icon:render()
        end
    end

    function icon_manager:handleClick(event_type, x_pos, y_pos)
        if event_type == "touch" then
            local clicked_icon, can_trigger, can_drag = self:handleTouch(x_pos, y_pos)
            if clicked_icon and can_drag then
                self:startDrag(clicked_icon, x_pos, y_pos)
                self.dragging = true
            elseif clicked_icon and can_trigger then
                clicked_icon:trigger()
        end
        elseif event_type == "drag" and self.dragging then
            self:updateDrag(x_pos, y_pos)
        elseif event_type == "drop" and self.dragging then
            self:stopDrag(x_pos, y_pos)
            self.dragging = false
        end
    end

    function icon_manager:handleTouch(x_pos, y_pos)
        for i = #self.icons, 1, -1 do
            local clicked_icon = self.icons[i]
            if clicked_icon:isPointInsideIcon(x_pos, y_pos) then
                local can_trigger = clicked_icon:canTrigger()
                local can_drag = clicked_icon:canDrag()
                return clicked_icon, can_trigger, can_drag
            end
        end
    end

    function icon_manager:startDrag(icon, start_x, start_y)
        self.dragged = {
        icon = icon,
        offset_x = start_x - icon.x,
        offset_y = start_y - icon.y
    }
    end

    function icon_manager:updateDrag(x_pos, y_pos)
        local icon = self.dragged.icon
        if icon then
            local new_x = x_pos - self.dragged.offset_x
            local new_y = y_pos - self.dragged.offset_y
            self.dragged.icon:move(new_x, new_y)
        end
    end

    function icon_manager:stopDrag(x_pos, y_pos)
        local icon = self.dragged.icon
        if self.dragged.icon then
            local new_x = x_pos - self.dragged.offset_x
            local new_y = y_pos - self.dragged.offset_y
            icon:snapToGrid(new_x, new_y)
        end
        self.dragged = {}
    end

return icon_manager