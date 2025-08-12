-- /lib/core/keyboard/keyboard_map.lua
-- Contains complete I/O for keyboard input handling.

local keyboard_codes = require("core.keyboard_codes")
local keyboard = require("core.keyboard")

local key_map = {}

local letters = "abcdefghijklmnopqrstuvwxyz"
local numbers = "0123456789"
local symbol_definitions = {
    ["="] = "EQUAL",
    ["["] = "LBRACKET",
    ["]"] = "RBRACKET",
    ["\\"] = "BACKSLASH",
    [";"] = "SEMICOLON",
    ["'"] = "APOSTROPHE",
    [","] = "COMMA",
    ["."] = "PERIOD",
    ["/"] = "SLASH",
    ["*"] = "ASTERISK",
    ["+"] = "ADD",
    ["-"] = "SUBTRACT",
    ["`"] = "GRAVE_ACCENT",
}

for i = 1, #letters do
    local letter = letters:sub(i, i)
    key_map[keyboard_codes["KEY_" .. letter:upper()]] = function() return keyboard.typeLetter(letter) end
end

for i = 1, #numbers do
    local number = numbers:sub(i, i)
    key_map[keyboard_codes["NUM_" .. number]] = function() return keyboard.typeLetter(number) end
    key_map[keyboard_codes["NUMPAD_" .. number]] = function() return keyboard.typeLetter(number) end
end

for symbol, definition in pairs(symbol_definitions) do
    key_map[keyboard_codes["KEY_" .. definition]] = function() return keyboard.typeLetter(symbol) end
    key_map[keyboard_codes["NUMPAD_" .. symbol]] = function() return keyboard.typeLetter(symbol) end
end

key_map[keyboard_codes.KEY_SPACE] = function() return keyboard.typeLetter(" ") end
key_map[keyboard_codes.KEY_ENTER] = function() return keyboard.typeLetter("\n") end
key_map[keyboard_codes.KEY_NUMPAD_ENTER] = function() return keyboard.typeLetter("\n") end
key_map[keyboard_codes.KEY_BACKSPACE] = function() return keyboard.backspace() end
key_map[keyboard_codes.KEY_DELETE] = function() return keyboard.delete() end
key_map[keyboard_codes.KEY_TAB] = function() return keyboard.typeLetter("\t") end
key_map[keyboard_codes.KEY_CAPSLOCK] = function() keyboard.toggleCapsLock() end
key_map[keyboard_codes.KEY_UP_ARROW] = function(y_position, min_y) return keyboard.upArrow(y_position, min_y) end
key_map[keyboard_codes.KEY_DOWN_ARROW] = function(y_position, max_y) return keyboard.downArrow(y_position, max_y) end
key_map[keyboard_codes.KEY_LEFT_ARROW] = function(x_position, min_x) return keyboard.leftArrow(x_position, min_x) end
key_map[keyboard_codes.KEY_RIGHT_ARROW] = function(x_position, max_x) return keyboard.rightArrow(x_position, max_x) end
key_map[keyboard_codes.KEY_HOME] = function(buffer_position, min_buffer_position) return keyboard.home(buffer_position, min_buffer_position) end
key_map[keyboard_codes.KEY_END] = function(buffer_position, max_buffer_position) return keyboard.endKey(buffer_position, max_buffer_position) end
key_map[keyboard_codes.KEY_PGUP] = function(y_position, min_y) return keyboard.pageUp(y_position, min_y) end
key_map[keyboard_codes.KEY_PGDN] = function(y_position, max_y) return keyboard.pageDown(y_position, max_y) end

function key_map.remapKey(key, new_function)
        key_map[key] = new_function
end

return key_map