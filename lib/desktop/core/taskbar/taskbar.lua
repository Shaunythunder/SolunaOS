-- /lib/gui/core/taskbar.lua

local colors = require("colors")
local drawgui = require("drawgui")
local assets = require("assets")


local taskbar = {}
taskbar.__index = taskbar

function taskbar.new()
    local self = setmetatable({}, taskbar)
    local h = _G.height
    local w = _G.width
    if assets.TASKBAR then
        self.image = assets.TASKBAR
    else
        self.image = nil
    end
    self.x_pos = 1
    self.y_pos = h - 2
    self.height = 3
    self.width = w
    self.bg_color = colors.DARKGRAY
    return self
end

function taskbar:terminate()
    for attribute in pairs(self) do
        self[attribute] = nil
    end
    setmetatable(self, nil)
end

function taskbar:render()
    drawgui.renderTaskbar(self)
end

function taskbar:getHeight()
    return self.height
end

function taskbar:setBackgroundColor(color)
    self.bg_color = color
end

function taskbar:addIcon(icon)
    table.insert(self.icons, icon)
end

function taskbar:getIcons()
    return self.icons
end

return taskbar