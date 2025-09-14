-- /lib/gui/core/taskbar/start_button.lua

local assets = require("assets")
local drawgui = require("drawgui")

local start_button = {}
start_button.__index = start_button

    function start_button.new(taskbar)
        local self = setmetatable({}, start_button)
        local h = _G.height
        self.image_unclicked = assets.START_BUTTON_UNCLICKED
        self.image_clicked = assets.START_BUTTON_CLICKED
        self.x_pos = 3
        self.y_pos = taskbar.y_pos
        self.width = 6
        self.height = 3
        self.clicked = false
        return self
    end

    function start_button:terminate()
        for attribute in pairs(self) do
            self[attribute] = nil
        end
        setmetatable(self, nil)
    end

    function start_button:render()
        drawgui.renderStartButton(self)
    end

    function start_button:toggleClicked()
        self.clicked = not self.clicked
    end

    function start_button:clicked()
        self.clicked = true
    end

    function start_button:unclicked()
        self.clicked = false
    end

    function start_button:isPointInButton(x_pos, y_pos)
        return x_pos >= self.x_pos and x_pos < self.x_pos + self.width and
               y_pos >= self.y_pos and y_pos < self.y_pos + self.height
    end

return start_button