-- /lib/gui/core/taskbar/taskbar_manager.lua

local taskbar = require("taskbar")
local ram_meter = require("ram_meter")
local taskbar_menu = require("taskbar_menu")
local start_button = require("start_button")

local taskbar_manager = {}
taskbar_manager.__index = taskbar_manager

    function taskbar_manager.new()
        local self = setmetatable({}, taskbar_manager)
        self.app_manager = nil
        self.window_manager = nil
        self.taskbar = taskbar.new()
        self.ram_meter = ram_meter.new(self.taskbar)
        self.start_button = start_button.new(self.taskbar)
        self.taskbar_menu = taskbar_menu.new(self.start_button)
        self.menu = nil
        self.icons = {}
        return self
    end

    function taskbar_manager:terminate()
        self.taskbar:terminate()
        self.ram_meter:terminate()
        self.taskbar_menu:terminate()
        self.start_button:terminate()
        for attribute in pairs(self) do
            self[attribute] = nil
        end
        setmetatable(self, nil)
    end

    function taskbar_manager:setWindowManager(window_manager)
        self.window_manager = window_manager
    end

    function taskbar_manager:setAppManager(app_manager)
        self.app_manager = app_manager
    end

    function taskbar_manager:handleClick(event_type, x_pos, y_pos)
        if event_type == "touch" then
            if self.start_button:isPointInButton(x_pos, y_pos) then
                self.start_button:toggleClicked()
                self.taskbar_menu:toggleVisibility()
            elseif not self.start_button:isPointInButton(x_pos, y_pos)
            and self.taskbar_menu:isPointInMenu(x_pos, y_pos) then
                if self.taskbar_menu:getVisibility() then
                    self.taskbar_menu:triggerItem(x_pos, y_pos)
                end
            else
                self.start_button:unclicked()
                self.taskbar_menu:notVisible()
            end
        elseif event_type == "drag" then
            return
        elseif event_type == "drop" then
            return
        end
    end

    function taskbar_manager:renderAll()
        self.taskbar:render()
        self.ram_meter:render()
        self.start_button:render()
        self.taskbar_menu:render()
        -- Future: Render start button, clock, and icons
    end

    function taskbar_manager:pinIcon(icon)
        table.insert(self.icons, icon)
    end

    function taskbar_manager:unpinIcon(icon)
        for i, value in ipairs(self.icons) do
            if value == icon then
                table.remove(self.icons, i)
                break
            end
        end
    end

    

return taskbar_manager