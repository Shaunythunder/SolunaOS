-- /lib/core/keyboard/keyboard.lua
-- Keyboard input management module

local keyboard = {}
keyboard.__index = keyboard

function keyboard.new()
    local self = setmetatable({}, keyboard)
    self.shift = false
    self.ctrl = false
    self.alt = false
    self.capslock = false
    self.keys = {}
    self:initKeys()
    return self
end

function keyboard:initKeys()
    local keys = require("keyboard_codes")
    self.keys = keys
end

function keyboard:getKeyName(code)
    for _, key_entry in pairs(self.keys) do
        if key_entry.code == code then
            return key_entry.name
        end
    end
    return nil
end

function keyboard:getKeyHandler(code)
    for _, key_entry in pairs(self.keys) do
        if key_entry.code == code then
            return key_entry.handler
        end
    end
    return nil
end

function keyboard:remapKey(code, new_handler)
    for _, key_entry in pairs(self.keys) do
        if key_entry.code == code then
            key_entry.handler = new_handler
            return true
        end
    end
    return false
end
    
function keyboard:reset()
    self.shift = false
    self.ctrl = false
    self.alt = false
    self.capslock = false
end

function keyboard:terminate()
    for attribute in pairs(self) do
        self[attribute] = nil -- Clear methods to free up memory
    end
    setmetatable(self, nil)
    collectgarbage()
end

function keyboard:isShiftPressed()
    return self.shift
end

function keyboard:shiftToggle()
    self.shift = not self.shift
end


function keyboard:isCtrlPressed()
    return self.ctrl
end

function keyboard:ctrlToggle()
    self.ctrl = not self.ctrl
end

function keyboard:isAltPressed()
    return self.alt
end

function keyboard:altToggle()
    self.alt = not self.alt
end

function keyboard:isCapsLockOn()
    return self.capslock
end

function keyboard:capsLockToggle()
    self.capslock = not self.capslock
end

function keyboard:upArrow(y_position, min_y)
    local movement = 1
    if self.ctrl then
        movement = 4
    end
    if y_position and y_position > min_y then
        y_position = y_position - movement
    end
    return y_position
end

function keyboard:downArrow(y_position, max_y)
    local movement = 1
    if self.ctrl then
        movement = 4
    end
    if y_position and y_position < max_y then
        y_position = y_position + movement
    end
    return y_position
end

function keyboard:leftArrow(x_position, min_x)
    local movement = 1
    if self.ctrl then
        movement = 4
    end
    if x_position and x_position > min_x then
        x_position = x_position - movement
    end
    return x_position
end

function keyboard:rightArrow(x_position, max_x)
    local movement = 1
    if self.ctrl then
        movement = 4
    end
    if x_position and x_position < max_x then
        x_position = x_position + movement
    end
    return x_position
end

function keyboard:home(buffer_position, min_buffer_position)
    if buffer_position and buffer_position > min_buffer_position then
        buffer_position = min_buffer_position
    end
    return buffer_position
end

function keyboard:endKey(buffer_position, max_buffer_position)
    if buffer_position and buffer_position < max_buffer_position then
        buffer_position = max_buffer_position
    end
    return buffer_position
end


function keyboard:backspace(string, position)
    if position and position > 1 then
        string = string:sub(1, position - 2) .. string:sub(position)
        position = position - 1
        return string, position
    else
        return string, position
    end
end

function keyboard:delete(string, position)
    if position and position <= #string then
        string = string:sub(1, position - 1) .. string:sub(position + 1)
        return string, position
    else
        return string, position
    end
end

function keyboard:pageUp(y_position, min_y)
    local movement = 23
    if y_position and y_position > min_y then
        y_position = y_position - movement
    end
    if y_position < min_y then
        y_position = min_y
    end
    return y_position
end

function keyboard:pageDown(y_position, max_y)
    local movement = 23
    if y_position and y_position < max_y then
        y_position = y_position + movement
    end
    if y_position > max_y then
        y_position = max_y
    end
    return y_position
end

function keyboard:typeLetter(letter)
    if self.capslock ~= self.shift then
        letter:upper()
    else
        letter:lower()
    end
    return letter
end

function keyboard:typeSymbol(symbol)
    local shift_symbols = {
        ["1"] = "!",
        ["2"] = "@",
        ["3"] = "#",
        ["4"] = "$",
        ["5"] = "%",
        ["6"] = "^",
        ["7"] = "&",
        ["8"] = "*",
        ["9"] = "(",
        ["0"] = ")",
        ["-"] = "_",
        ["="] = "+",
        ["["] = "{",
        ["]"] = "}",
        ["\\"] = "|",
        [";"] = ":",
        ["'"] = "\"",
        [","] = "<",
        ["."] = ">",
        ["/"] = "?",
        ["`"] = "~"
    }
    if self.shift and shift_symbols[symbol] then
        return shift_symbols[symbol]
    else
        return symbol
    end
end

return keyboard