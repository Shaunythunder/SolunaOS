local window = require("window")
local Window_manager = require("window_manager")
local Taskbar_manager = require("taskbar_manager")
local App_manager = require("app_manager")
local drawgui = require("drawgui")
local icon = require("icon")
local colors = require("colors")

local window_manager = Window_manager.new()
local taskbar_manager = Taskbar_manager.new()
local app_manager = App_manager.new()
taskbar_manager:setWindowManager(window_manager)
taskbar_manager:setAppManager(app_manager)

window_manager:setTaskbarManager(taskbar_manager)
window_manager:setAppManager(app_manager)

app_manager:setWindowManager(window_manager)
app_manager:setTaskbarManager(taskbar_manager)
local event = _G.event

-- Create test windows
local win1 = window.new(10, 5, 30, 10, nil, nil, "Window 1")
local win2 = window.new(20, 10, 25, 8, nil, nil, "Window 2")

local create_new_window_icon = icon.new(
    window_manager.app_manager,
    "🗔",
    nil,
    colors.LIGHTGRAY,
    2,
    _G.height - 4,
    "apps/create_window"
)

window_manager:add(win1)
window_manager:add(win2)

while true do
    -- Clear screen and render
    drawgui.renderBackground("fill")
    window_manager:renderAll()
    taskbar_manager:renderAll()
    create_new_window_icon:render()

    local event_type, _, x_pos, y_pos, _ = event:listen(0.05)
    window_manager:handleClick(event_type, x_pos, y_pos)
    taskbar_manager:handleClick(event_type, x_pos, y_pos)
end