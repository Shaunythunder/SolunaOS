-- lib/core/event/event.lua
-- Provides core event handling functionality for SolunaOS

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

function event:reset()
    self.event_handlers = {}
    self:initHandlers()
end

function event:listen()
    local event_type, arg1, arg2, arg3, arg4 = computer.pullSignal()
    if self.event_handlers[event_type] then
        self.event_handlers[event_type](event_type, arg1, arg2, arg3, arg4)
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