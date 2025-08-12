

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

return event_handlers