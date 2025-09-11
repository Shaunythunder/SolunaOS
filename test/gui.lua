local window = require("window")
local window_manager = require("window_manager")
local drawgui = require("drawgui")

local window_manager = window_manager.new()
local event = _G.event

-- Create test windows
local win1 = window.new(10, 5, 30, 10, nil, nil, "Window 1")
local win2 = window.new(20, 10, 25, 8, nil, nil, "Window 2")

window_manager:add(win1)
window_manager:add(win2)

local dragging = false

while true do
    -- Clear screen and render
    drawgui.renderBackground("fill")
    window_manager:renderAll()
    drawgui.renderTaskbar()

    local event_type, _, x_pos, y_pos, _ = event:listen(0.05)

    if event_type == "touch" then
        local clicked_window = window_manager:handleClick(x_pos, y_pos)
        if clicked_window and clicked_window:isPointInTitleBar(x_pos, y_pos) then
            window_manager:startDrag(clicked_window, x_pos, y_pos)
            dragging = true
        end
    elseif event_type == "drag" and dragging then
        window_manager:updateDrag(x_pos, y_pos)
    elseif event_type == "drop" then
        window_manager:stopDrag()
        dragging = false
    end
end