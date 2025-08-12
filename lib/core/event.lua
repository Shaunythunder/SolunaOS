-- lib/core/event.lua
-- Provides core event handling functionality for SolunaOS
local os = require("os")

local event = {}

event.handlers = {}

function event.on (event_type, handler)
    event.handlers[event_type] = event.handlers[event_type] or {}
    table.insert(event.handlers[event_type], handler)
end

function event.emit(event_type, ...)

end

function event.pull()
    -- Wait for an event to occur and return the event type and associated data
    return os.pullSignal()
end

return event