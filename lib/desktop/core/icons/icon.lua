-- /lib/gui/core/taskbar/taskbar_icons.lua

local drawgui = require("drawgui")

local icon = {}
icon.__index = icon

function icon.new(icon_manager, app_manager, label, image, color, x_pos, y_pos, app_path)
    local self = setmetatable({}, icon)
    self.icon_manager = icon_manager
    self.app_manager = app_manager
    self.image = image
    self.label = label
    self.color = color
    self.x_pos = x_pos
    self.y_pos = y_pos
    self.width = 6
    self.height = 3
    self.app_path = app_path
    self.pinned = false
    self.first_click = false
    self.second_click = false
    return self
end

function icon:terminate()
    for attribute in pairs(self) do
        self[attribute] = nil
    end
    setmetatable(self, nil)
end

function icon:render()
    drawgui.renderIcon(self)
end

function icon:move(new_x, new_y)
    local h = _G.height
    local w = _G.width
    local taskbar_height = self.icon_manager.taskbar_manager.taskbar:getHeight()
    local taskbar_y = h - taskbar_height + 1
    if new_x < 1 then
        new_x = 1
    end
    if new_y < 1 then
        new_y = 1
    end
    if new_x + self.width > w then
        new_x = w - self.width + 1
    end
    if new_y + self.height > taskbar_y then
        new_y = taskbar_y - self.height
    end
    self.x_pos = new_x
    self.y_pos = new_y
end

function icon:snapToGrid(new_x, new_y)
    if not (new_x % 2 == 0) then
        new_x = new_x - 1
    end
    if not (new_y % 2 == 0) then
        new_y = new_y - 1
    end
    self.x_pos = new_x
    self.y_pos = new_y
end

function icon:isPointInsideIcon(x_pos, y_pos)
    return x_pos >= self.x_pos and x_pos < self.x_pos + self.width and
            y_pos >= self.y_pos and y_pos < self.y_pos + self.height
end

function icon:togglePinned()
    self.pinned = not self.pinned
end

function icon:pin()
    self.pinned = true
end

function icon:unpin()
    self.pinned = false
end

function icon:getPinned()
    return self.pinned
end

function icon:getApp()
    return self.app
end

function icon:canDrag()
    local current_time = os.clock()
    if current_time - self.last_click_time >= self.click_interval then
        return true
    end
    return false
end

function icon:handleClick()
    if not self.first_click then
        self.first_click = true
        self.second_click = false
    elseif self.first_click and not self.second_click then
        self.second_click = true
        self:trigger()
        return true
    end
    return false
end

function icon:unclicked()
    self.first_click = false
    self.second_click = false
end

function icon:trigger()
    if self.app_path then
        if self.second_click then
            self.app_manager:launchApp(self.app_path)
            self:unclicked()
            return true
        end
    end
    return false
end

return icon