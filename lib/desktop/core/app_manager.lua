-- // lib/desktop/core/app_launcher.lua

local app_manager = {}
app_manager.__index = app_manager

function app_manager.new()
    local self = setmetatable({}, app_manager)
    self.window_manager = nil
    self.taskbar_manager = nil
    self.active_apps = {}
    self.focused_app = nil
    return self
end

function app_manager:terminate()
    for attribute in pairs(self) do
        self[attribute] = nil
    end
    setmetatable(self, nil)
end

function app_manager:setWindowManager(window_manager)
    self.window_manager = window_manager
end

function app_manager:setTaskbarManager(taskbar_manager)
    self.taskbar_manager = taskbar_manager
end

function app_manager:focus(app)
    self.focused_app = app
end

function app_manager:unfocus()
    self.focused_app = nil
end

function app_manager:passEventToFocusedApp(...)
    if self.focused_app and type(self.focused_app.handleEvent) == "function" then
        self.focused_app:handleEvent(...)
    end
end

function app_manager:launchApp(app_path, ...)
    if self.window_manager == nil then
        error("Window manager not set. Cannot launch app.")
    end
    if self.taskbar_manager == nil then
        error("Taskbar manager not set. Cannot launch app.")
    end
    local app = require(app_path)
    local app_instance = app.new(...)
    self.window_manager:add(app_instance.window)
    table.insert(self.active_apps, app_instance)
end

function app_manager:closeApp(app_instance)
    if app_instance and type(app_instance) == "table" then
        for i, app in ipairs(self.active_apps) do
            if app == app_instance then
                table.remove(self.active_apps, i)
                break
            end
        end
    else
        error("Invalid app instance provided for termination.")
    end
end

return app_manager