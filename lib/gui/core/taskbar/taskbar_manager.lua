-- /lib/gui/core/taskbar/taskbar_manager.lua

local taskbar = require("taskbar")
local ram_meter = require("ram_meter")
local start_button = require("start_button")

local taskbar_manager = {}
taskbar_manager.__index = taskbar_manager

    function taskbar_manager.new()
        local self = setmetatable({}, taskbar_manager)
        self.taskbar = taskbar.new()
        self.ram_meter = ram_meter.new(self.taskbar)
        self.start_button = start_button.new(self.taskbar)
        self.menu = nil
        self.icons = {}
        return self
    end

    function taskbar_manager:terminate()
        self.taskbar:terminate()
        self.ram_meter:terminate()
        self.start_button:terminate()
        self.clock:terminate()
        self.menu:terminate()
        for attribute in pairs(self) do
            self[attribute] = nil
        end
        setmetatable(self, nil)
    end

    function taskbar_manager:renderAll()
        self.taskbar:render()
        self.ram_meter:render()
        self.start_button:render()
        -- Future: Render start button, clock, and icons
    end

return taskbar_manager