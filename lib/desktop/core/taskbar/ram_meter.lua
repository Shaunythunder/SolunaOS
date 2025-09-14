-- /lib/gui/core/taskbar/ram_meter.lua

local sys = require("system")
local drawgui = require("drawgui")
local colors = require("colors")

local ram_meter = {}
ram_meter.__index = ram_meter

function ram_meter.new(taskbar)
    local self = setmetatable({}, ram_meter)
    local h = _G.height
    local w = _G.width
    self.text = "  RAM Usage  "
    self.x_pos = w - #self.text - 1
    self.y_pos = taskbar.y_pos + 1
    self.taskbar_color = taskbar.bg_color or colors.DARKGRAY
    self.width = #self.text
    self.height = 1
    self.total_ram = 0
    self.used_ram = 0
    self.percent_used = 0
    self.last_update = 0
    self.update_interval = .05
    self:setRamInfo()
    return self
end

function ram_meter:terminate()
    for attribute in pairs(self) do
        self[attribute] = nil
    end
    setmetatable(self, nil)
end

function ram_meter:setRamInfo()
    self.total_ram = sys.totalMemory()
    self.used_ram = sys.usedMemory()
end

function ram_meter:checkIfCanUpdate()
    local current_time = os.clock()
    if (current_time - self.last_update) >= self.update_interval then
        self.last_update = current_time
        return true
    else
        return false
    end
end

function ram_meter:render()
    if self:checkIfCanUpdate() then
        self:setRamInfo()
    end
    drawgui.renderRamMeter(self)
end

return ram_meter
