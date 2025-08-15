-- lib/core/event.lua
-- Provides core event handling functionality for SolunaOS

local keyboard = _G.keyboard

local event = {}
event.__init = event

    event.new = function()
        local self = setmetatable({}, { __index = event })
        self.event_handlers = {}
        --self:initHandlers()
        return self
    end

    function event:initHandlers()
        local event_handlers = require("event_handlers")
        self.event_handlers = event_handlers
    end

    function event:getHandler(event_type)
        return self.event_handlers[event_type]
    end

    function event:getEventType(event_type)
        return self.event_handlers[event_type] and event_type or nil
    end

    function event:reset()
        self.event_handlers = {}
        self:initHandlers()
    end

    function event:listen()
        local event_type, arg1, arg2, arg3, arg4 = computer.pullSignal()
        if self.event_handlers[event_type] then
            self.event_handlers[event_type](event_type, arg1, arg2, arg3, arg4)
        end
        return event_type, arg1, arg2, arg3, arg4
    end

    --- Listens for keyboard events triggers keyboard functions.
    --- @param timeout number|nil
    --- @return function|nil triggerKeyEvent (key_code)
    function event:keyboardListen(timeout)
        local event_type, _, _, key_code, _ = computer.pullSignal(timeout)
        if event_type == "key_down" then
            return keyboard:triggerKeyDown(key_code)
        elseif event_type == "key_up" then
            return keyboard:triggerKeyUp(key_code)
        end
    end

    ---@param overwrite boolean
    function event:bind(event_type, handler, overwrite)
        if overwrite then
            self.event_handlers[event_type] = { handler }
        else
            self.event_handlers[event_type] = self.event_handlers[event_type] or {}
            table.insert(self.event_handlers[event_type], handler)
        end
    end

    function event:triggerSpecific(event_type, handler, ...)
        if self.event_handlers[event_type] then
            for _, hdlr in ipairs(self.event_handlers[event_type]) do
                if hdlr == handler then
                    hdlr(event_type, ...)
                end
            end
        end
    end

    function event:triggerAll(event_type, ...)
        if self.event_handlers[event_type] then
            for _, handler in ipairs(self.event_handlers[event_type]) do
                handler(event_type, ...)
            end
        end
    end

    function event.pull()
        -- Wait for an event to occur and return the event type and associated data
        return computer.pullSignal()
    end

    local event_handlers = {
        KEY_DOWN = {code = "key_down", handler = nil},
        KEY_UP = {code = "key_up", handler = nil},
        CLIPBOARD = {code = "clipboard", handler = nil},
        TOUCH = {code = "touch", handler = nil},
        DRAG = {code = "drag", handler = nil},
        DROP = {code = "drop", handler = nil},
        WALK = {code = "walk", handler = nil},
        COMPONENT_ADDED = {code = "component_added", handler = nil},
        COMPONENT_REMOVED = {code = "component_removed", handler = nil},
        COMPONENT_AVAILABLE = {code = "component_available", handler = nil},
        COMPONENT_UNAVAILABLE = {code = "component_unavailable", handler = nil},
        COMPUTER_STOPPED = {code = "computer_stopped", handler = nil},
        COMPUTER_STARTED = {code = "computer_started", handler = nil},
        COMPUTER_BEEP = {code = "computer_beep", handler = nil},
        INTERRUPTED = {code = "interrupted", handler = nil},
        MODEM_MESSAGE = {code = "modem_message", handler = nil},
        ALARM = {code = "alarm", handler = nil},
        SCREEN_RESIZED = {code = "screen_resized", handler = nil},
        TERM_AVAILABLE = {code = "term_available", handler = nil},
        TERM_UNAVAILABLE = {code = "term_unavailable", handler = nil},
        TIMER = {code = "timer", handler = nil}
    }

return event