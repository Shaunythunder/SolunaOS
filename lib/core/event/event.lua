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
    self.handlers = event_handlers
end

function event.emit(event_type, ...)

end

function event.pull()
    -- Wait for an event to occur and return the event type and associated data
    return os.pullSignal()
end

return event