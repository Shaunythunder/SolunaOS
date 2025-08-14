-- lib/core/event/event.lua
-- Provides core event handling functionality for SolunaOS


local keyboard = _G.keyboard


local LSHIFT = keyboard.keys.K_LSHIFT.code
local RSHIFT = keyboard.keys.K_RSHIFT.code
local LCTRL = keyboard.keys.K_LCTRL.code
local RCTRL = keyboard.keys.K_RCTRL.code
local LALT = keyboard.keys.K_LALT.code
local RALT = keyboard.keys.K_RALT.code
local CAPSLOCK = keyboard.keys.K_CAPSLOCK.code

local event = {}
event.__init = event

event.new = function()
    local self = setmetatable({}, { __index = event })
    self.event_handlers = {}
    self:initHandlers()
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

function event:keyboardListen(timeout)
    local event_type, _, _, key_code, _ = computer.pullSignal(timeout)
    if event_type == "key_down" then
        return _G.keyboard:triggerKeyDown(key_code)
    elseif event_type == "key_up" then
        return _G.keyboard:triggerKeyUp(key_code)
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

return event