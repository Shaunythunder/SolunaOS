-- /lib/gui/core/taskbar/taskbar_menu.lua

local colors = require("colors")
local drawgui = require("drawgui")
local shutdown = require("shutdown")
local reboot = require("reboot")

local taskbar_menu = {}
taskbar_menu.__index = taskbar_menu

    function taskbar_menu.new(start_button)
        local self = setmetatable({}, taskbar_menu)
        self.items = {}
        self.visible = false
        self.width = 20
        self.height = 10
        self.x_pos = start_button.x_pos
        self.y_pos = start_button.y_pos - self.height
        self.bg_color = colors.LIGHTGRAY
        self.text_color = colors.BLACK
        self:loadItems()
        return self
    end

    function taskbar_menu:terminate()
        for attribute in pairs(self) do
            self[attribute] = nil
        end
        setmetatable(self, nil)
    end

    function taskbar_menu:toggleVisibility()
        self.visible = not self.visible
    end

    function taskbar_menu:getVisibility()
        return self.visible
    end

    function taskbar_menu:notVisible()
        self.visible = false
    end

    function taskbar_menu:render()
        if self.visible then
            drawgui.renderTaskbarMenu(self)
        end
    end

    function taskbar_menu:isPointInMenu(x_pos, y_pos)
        if not self.visible then
            return false
        end
        self:triggerItem(x_pos, y_pos)
        return x_pos >= self.x_pos and x_pos < self.x_pos + self.width and
               y_pos >= self.y_pos and y_pos < self.y_pos + self.height
    end

    function taskbar_menu:isPointInItem(x_pos, y_pos)
        if not self.visible then
            return nil
        end
        for index, item in ipairs(self.items) do
            if item.x_pos and item.y_pos then
                if x_pos >= item.x_pos and x_pos < item.x_pos + self.width and
                   y_pos == item.y_pos then
                    return index
                end
            end
        end
        return nil
    end

    function taskbar_menu:triggerItem(x_pos, y_pos)
        local item_index = self:isPointInItem(x_pos, y_pos)
        if item_index and self.items[item_index] and self.items[item_index].action then
            self.items[item_index].action()
            return true
        end
        return false
    end

    function taskbar_menu:loadItems()
        self.items = {
           {name = "Shutdown", x_pos = 0, y_pos = 0, action = function() shutdown.execute() end},
           {name = "Restart", x_pos = 0, y_pos = 0, action = function() reboot.execute() end},
           {name = "Settings", x_pos = 0, y_pos = 0, action = nil},
           {name = "Open Terminal", x_pos = 0, y_pos = 0, action = nil},
           {name = "Open File Manager", x_pos = 0, y_pos = 0, action = nil},
           {name = "Help", x_pos = 0, y_pos = 0, action = nil},
           {name = "Lock Screen", x_pos = 0, y_pos = 0, action = nil},
           {name = "Logout", x_pos = 0, y_pos = 0, action = nil},
           {name = "About", x_pos = 0, y_pos = 0, action = nil},
        }
        for index, item in pairs(self.items) do
            if item.name and item.action then
                item.x_pos = self.x_pos
                item.y_pos = self.y_pos + self.height - index
            end
        end

    end

return taskbar_menu