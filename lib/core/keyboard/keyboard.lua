-- /lib/core/keyboard/keyboard.lua
-- Keyboard input management module

local keyboard = {}
keyboard.__index = keyboard

function keyboard.new()
    local self = setmetatable({}, keyboard)
    self.left_shift = false
    self.right_shift = false
    self.left_ctrl = false
    self.right_ctrl = false
    self.left_alt = false
    self.right_alt = false
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

function keyboard:getKeyDown(code)
    for _, key_entry in pairs(self.keys) do
        if key_entry.code == code then
            return key_entry.key_down
        end
    end
    return nil
end

function keyboard:triggerKeyDown(code)
    local key_down_handler = nil
    for _, key_entry in pairs(self.keys) do
        if key_entry.code == code then
            key_down_handler = key_entry.key_down
        end
    end
    if key_down_handler ~= nil then
        return key_down_handler(self)
    end
end

function keyboard:triggerKeyUp(code)
    local key_up_handler = nil
    for _, key_entry in pairs(self.keys) do
        if key_entry.code == code then
            key_up_handler = key_entry.key_up
        end
    end
    if key_up_handler ~= nil then
        return key_up_handler(self)
    end
end

function keyboard:getKeyUp(code)
    for _, key_entry in pairs(self.keys) do
        if key_entry.code == code then
            return key_entry.key_up
        end
    end
    return nil
end

function keyboard:remapKey(code, key_down, key_up)
    for _, key_entry in pairs(self.keys) do
        if key_entry.code == code then
            key_entry.key_down = key_down
            key_entry.key_up = key_up
            return true
        end
    end
    return false
end
    
function keyboard:reset()
    self.left_shift = false
    self.right_shift = false
    self.left_ctrl = false
    self.right_ctrl = false
    self.left_alt = false
    self.right_alt = false
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
    if self.left_shift or self.right_shift then
        return true
    end
    return false
end

function keyboard:leftShiftUp()
    self.left_shift = false
end

function keyboard:rightShiftUp()
    self.right_shift = false
end

function keyboard:leftShiftDown()
    self.left_shift = true
end

function keyboard:rightShiftDown()
    self.right_shift = true
end

function keyboard:isCtrlPressed()
    if self.left_ctrl or self.right_ctrl then
        return true
    end
    return false
end

function keyboard:leftCtrlUp()
    self.left_ctrl = false
end

function keyboard:rightCtrlUp()
    self.right_ctrl = false
end

function keyboard:leftCtrlDown()
    self.left_ctrl = true
end

function keyboard:rightCtrlDown()
    self.right_ctrl = true
end

function keyboard:isAltPressed()
    if self.left_alt or self.right_alt then
        return true
    end
    return false
end
    
function keyboard:leftAltUp()
    self.left_alt = false
end

function keyboard:rightAltUp()
    self.right_alt = false
end

function keyboard:leftAltDown()
    self.left_alt = true
end

function keyboard:rightAltDown()
    self.right_alt = true
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
    if (self.left_shift or self.right_shift) ~= self.capslock then
        letter = letter:upper()
    else
        letter = letter:lower()
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
    if (self.left_shift or self.right_shift) and shift_symbols[symbol] then
        return shift_symbols[symbol]
    else
        return symbol
    end
end

return keyboard