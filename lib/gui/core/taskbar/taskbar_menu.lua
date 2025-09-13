-- /lib/gui/core/taskbar/taskbar_menu.lua

local taskbar_menu = {}
taskbar_menu.__index = taskbar_menu

    function taskbar_menu.new()
        local self = setmetatable({}, taskbar_menu)
        self.taskbar = nil
        self.ram_meter = nil
        self.start_button = nil
        self.clock = nil
        self.menu = nil
        self.icons = {}
        return self
    end

return taskbar_menu