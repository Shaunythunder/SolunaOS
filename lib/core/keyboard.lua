-- /lib/core/keyboard/keyboard.lua
-- Keyboard input management module
-- Special functions such as arrow keys, page up/down, home/end, insert/delete,
-- enter, backspace, etc. are handled app-side. The keyboard sends a
-- special character to signify key such as "\n" for enter.

local keyboard = {}
    keyboard.__index = keyboard

    --- Initializes a new keyboard instance
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

    --- Restores default settings of keyboard
    --- @return nil
    function keyboard:reset()
        self.left_shift = false
        self.right_shift = false
        self.left_ctrl = false
        self.right_ctrl = false
        self.left_alt = false
        self.right_alt = false
        self.capslock = false
        self.keys = {}
        self:initKeys()
    end

    -- Binds a key code to a key down and key up handler
    --- @param code number key code to bind, see keyboard_codes.lua for codes
    --- @param key_down function function to call when the key is pressed
    --- @param key_up function the function to call when the key is released
    --- @return boolean true if the key was bound successfully, false otherwise
    function keyboard:bindKey(code, key_down, key_up)
        for _, key_entry in pairs(self.keys) do
            if key_entry.code == code then
                key_entry.key_down = key_down
                key_entry.key_up = key_up
                return true
            end
        end
        return false
    end

    --- Pulls the key down handler for a given key code and runs the function
    --- @param code number key code to trigger
    --- @return any result of the key down handler function, or nil if none assigned
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

    --- Pulls the key up handler for a given key code and runs the function
    --- @param code number key code to trigger
    --- @return any result of the key up handler function, or nil if none assigned
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

    --- Flips left shift flag on key up.
    --- @return nil
    function keyboard:leftShiftUp()
        self.left_shift = false
    end

    --- Flips right shift flag on key up.
    --- @return nil
    function keyboard:rightShiftUp()
        self.right_shift = false
    end

    --- Flips left shift flag on key down.
    --- @return nil
    function keyboard:leftShiftDown()
        self.left_shift = true
    end

    --- Flips right shift flag on key down.
    --- @return nil
    function keyboard:rightShiftDown()
        self.right_shift = true
    end

    --- Flips left ctrl flag on key up.
    --- @return nil
    function keyboard:leftCtrlUp()
        self.left_ctrl = false
    end

    --- Flips right ctrl flag on key up.
    --- @return nil
    function keyboard:rightCtrlUp()
        self.right_ctrl = false
    end

    --- Flips left ctrl flag on key down.
    --- @return nil
    function keyboard:leftCtrlDown()
        self.left_ctrl = true
    end

    --- Flips right ctrl flag on key down.
    --- @return nil
    function keyboard:rightCtrlDown()
        self.right_ctrl = true
    end

    --- Flips left alt flag on key up.
    --- @return nil
    function keyboard:leftAltUp()
        self.left_alt = false
    end

    --- Flips right alt flag on key up.
    --- @return nil
    function keyboard:rightAltUp()
        self.right_alt = false
    end

    --- Flips left alt flag on key down.
    --- @return nil
    function keyboard:leftAltDown()
        self.left_alt = true
    end

    --- Flips right alt flag on key down.
    --- @return nil
    function keyboard:rightAltDown()
        self.right_alt = true
    end

    --- Checks if caps lock is on.
    --- @return boolean true if caps lock is on, false otherwise
    function keyboard:isCapsLockOn()
        return self.capslock
    end

    --- Flips caps lock flag
    --- @return nil
    function keyboard:capsLockToggle()
        self.capslock = not self.capslock
    end

    --- Converts a letter to the correct case based on shift and caps lock state
    --- @param letter string the letter to convert
    --- @return string the converted letter
    function keyboard:typeLetter(letter)
        if (self.left_shift or self.right_shift) ~= self.capslock then
            letter = letter:upper()
        else
            letter = letter:lower()
        end
        return letter
    end

    --- Types a symbol, taking into account the current shift state
    --- Also sends special characters to signify keys for special handling such as "\n" for enter.
    --- @param symbol string the symbol to type
    --- @return string the typed symbol
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

    --- Initializes the keyboard with key codes and their handlers
    --- Contains default keyboard settings.
    --- @return nil
    function keyboard:initKeys()
        local keyboard = self

        -- Note I could not get LALT to function during testing. Possible hardware issue.

        local keys = {
            -- Function keys
            K_F1 = {code = 0x3B, handler = nil},
            K_F2 = {code = 0x3C, handler = nil},
            K_F3 = {code = 0x3D, handler = nil},
            K_F4 = {code = 0x3E, handler = nil},
            K_F5 = {code = 0x3F, handler = nil},
            K_F6 = {code = 0x40, handler = nil},
            K_F7 = {code = 0x41, handler = nil},
            K_F8 = {code = 0x42, handler = nil},
            K_F9 = {code = 0x43, handler = nil},
            K_F10 = {code = 0x44, handler = nil},
            K_F11 = {code = 0x57, handler = nil},
            K_F12 = {code = 0x58, handler = nil},
            K_F13 = {code = 0x64, handler = nil},
            K_F14 = {code = 0x65, handler = nil},
            K_F15 = {code = 0x66, handler = nil},
            K_F16 = {code = 0x67, handler = nil},
            K_F17 = {code = 0x68, handler = nil},
            K_F18 = {code = 0x69, handler = nil},
            K_F19 = {code = 0x71, handler = nil},

            -- Number Keys
            K_1 = {code = 0x02, key_down = function() return keyboard:typeSymbol("1") end, key_up = nil},
            K_2 = {code = 0x03, key_down = function() return keyboard:typeSymbol("2") end, key_up = nil},
            K_3 = {code = 0x04, key_down = function() return keyboard:typeSymbol("3") end, key_up = nil},
            K_4 = {code = 0x05, key_down = function() return keyboard:typeSymbol("4") end, key_up = nil},
            K_5 = {code = 0x06, key_down = function() return keyboard:typeSymbol("5") end, key_up = nil},
            K_6 = {code = 0x07, key_down = function() return keyboard:typeSymbol("6") end, key_up = nil},
            K_7 = {code = 0x08, key_down = function() return keyboard:typeSymbol("7") end, key_up = nil},
            K_8 = {code = 0x09, key_down = function() return keyboard:typeSymbol("8") end, key_up = nil},
            K_9 = {code = 0x0A, key_down = function() return keyboard:typeSymbol("9") end, key_up = nil},
            K_0 = {code = 0x0B, key_down = function() return keyboard:typeSymbol("0") end, key_up = nil},

            -- Operators
            K_SUBTRACT = {code = 0x0C, key_down = function() return keyboard:typeSymbol("-") end, key_up = nil},
            K_EQUAL = {code = 0x0D, key_down = function() return keyboard:typeSymbol("=") end, key_up = nil},
            K_BACKSPACE = {code = 0x0E, key_down = function() return keyboard:typeSymbol("\b") end, key_up = nil},
            K_TAB = {code = 0x0F, key_down = function() return keyboard:typeSymbol("\t") end, key_up = nil},
            K_CAPSLOCK = {code = 0x3A, key_down = function() return keyboard:capsLockToggle() end, key_up = nil},
            K_LSHIFT = {code = 0x2A, key_down = function() return keyboard:leftShiftDown() end, key_up = function() return keyboard:leftShiftUp() end},
            K_RSHIFT = {code = 0x36, key_down = function() return keyboard:rightShiftDown() end, key_up = function() return keyboard:rightShiftUp() end},
            K_LCTRL = {code = 0x1D, key_down = function() return keyboard:leftCtrlDown() end, key_up = function() return keyboard:leftCtrlUp() end},
            K_RCTRL = {code = 0x9D, key_down = function() return keyboard:rightCtrlDown() end, key_up = function() return keyboard:rightCtrlUp() end},
            K_LALT = {code = 0x38, key_down = function() return keyboard:leftAltDown() end, key_up = function() return keyboard:leftAltUp() end},
            K_RALT = {code = 0xB8, key_down = function() return keyboard:rightAltDown() end, key_up = function() return keyboard:rightAltUp() end},
            K_SPACE = {code = 0x39, key_down = function() return keyboard:typeSymbol(" ") end, key_up = nil},
            K_ENTER = {code = 0x1C, key_down = function() return keyboard:typeSymbol("\n") end, key_up = nil},
            K_PRT_SCR = {code = 0x00, key_down = function() return keyboard:typeLetter("prsc") end, key_up = nil},
            K_SCROLL_LOCK = {code = 0x46, key_down = function() return keyboard:typeLetter("scrlk") end, key_up = nil},
            K_PAUSE_BREAK = {code = 0x05, key_down = function() return keyboard:typeLetter("psbk") end, key_up = nil},
            K_INSERT = {code = 0xD2, key_down = function() return keyboard:typeLetter("ins") end, key_up = nil},
            K_HOME = {code = 0xC7, key_down = function() return keyboard:typeLetter("home") end, key_up = nil},
            K_PGUP = {code = 0xC9, key_down = function() return keyboard:typeLetter("pgup") end, key_up = nil},
            K_PGDN = {code = 0xD1, key_down = function() return keyboard:typeLetter("pgdn") end, key_up = nil},
            K_DEL = {code = 0xD3, key_down = function() return keyboard:typeLetter("del") end, key_up = nil},
            K_END = {code = 0xCF, key_down = function() return keyboard:typeLetter("end") end, key_up = nil},

            -- Letter Keys
            K_A = {code = 0x1E, key_down = function() return keyboard:typeLetter("a") end, key_up = nil},
            K_B = {code = 0x30, key_down = function() return keyboard:typeLetter("b") end, key_up = nil},
            K_C = {code = 0x2E, key_down = function() return keyboard:typeLetter("c") end, key_up = nil},
            K_D = {code = 0x20, key_down = function() return keyboard:typeLetter("d") end, key_up = nil},
            K_E = {code = 0x12, key_down = function() return keyboard:typeLetter("e") end, key_up = nil},
            K_F = {code = 0x21, key_down = function() return keyboard:typeLetter("f") end, key_up = nil},
            K_G = {code = 0x22, key_down = function() return keyboard:typeLetter("g") end, key_up = nil},
            K_H = {code = 0x23, key_down = function() return keyboard:typeLetter("h") end, key_up = nil},
            K_I = {code = 0x17, key_down = function() return keyboard:typeLetter("i") end, key_up = nil},
            K_J = {code = 0x24, key_down = function() return keyboard:typeLetter("j") end, key_up = nil},
            K_K = {code = 0x25, key_down = function() return keyboard:typeLetter("k") end, key_up = nil},
            K_L = {code = 0x26, key_down = function() return keyboard:typeLetter("l") end, key_up = nil},
            K_M = {code = 0x32, key_down = function() return keyboard:typeLetter("m") end, key_up = nil},
            K_N = {code = 0x31, key_down = function() return keyboard:typeLetter("n") end, key_up = nil},
            K_O = {code = 0x18, key_down = function() return keyboard:typeLetter("o") end, key_up = nil},
            K_P = {code = 0x19, key_down = function() return keyboard:typeLetter("p") end, key_up = nil},
            K_Q = {code = 0x10, key_down = function() return keyboard:typeLetter("q") end, key_up = nil},
            K_R = {code = 0x13, key_down = function() return keyboard:typeLetter("r") end, key_up = nil},
            K_S = {code = 0x1F, key_down = function() return keyboard:typeLetter("s") end, key_up = nil},
            K_T = {code = 0x14, key_down = function() return keyboard:typeLetter("t") end, key_up = nil},
            K_U = {code = 0x16, key_down = function() return keyboard:typeLetter("u") end, key_up = nil},
            K_V = {code = 0x2F, key_down = function() return keyboard:typeLetter("v") end, key_up = nil},
            K_W = {code = 0x11, key_down = function() return keyboard:typeLetter("w") end, key_up = nil},
            K_X = {code = 0x2D, key_down = function() return keyboard:typeLetter("x") end, key_up = nil},
            K_Y = {code = 0x15, key_down = function() return keyboard:typeLetter("y") end, key_up = nil},
            K_Z = {code = 0x2C, key_down = function() return keyboard:typeLetter("z") end, key_up = nil},

            -- Special Characters
            K_GRAVE_ACCENT = {code = 0x29, key_down = function() return keyboard:typeSymbol("`") end, key_up = nil},
            K_SEMICOLON = {code = 0x27, key_down = function() return keyboard:typeSymbol(";") end, key_up = nil},
            K_COMMA = {code = 0x33, key_down = function() return keyboard:typeSymbol(",") end, key_up = nil},
            K_PERIOD = {code = 0x34, key_down = function() return keyboard:typeSymbol(".") end, key_up = nil},
            K_SLASH = {code = 0x35, key_down = function() return keyboard:typeSymbol("/") end, key_up = nil},
            K_BACKSLASH = {code = 0x2B, key_down = function() return keyboard:typeSymbol("\\") end, key_up = nil},
            K_LEFT_BRACKET = {code = 0x1A, key_down = function() return keyboard:typeSymbol("[") end, key_up = nil},
            K_RIGHT_BRACKET = {code = 0x1B, key_down = function() return keyboard:typeSymbol("]") end, key_up = nil},
            K_APOSTROPHE = {code = 0x28, key_down = function() return keyboard:typeSymbol("'") end, key_up = nil},

            -- Navigation Keys
            K_LEFT_ARROW = {code = 0xCB, key_down = function() return keyboard:typeSymbol("<-") end, key_up = nil},
            K_RIGHT_ARROW = {code = 0xCD, key_down = function() return keyboard:typeSymbol("->") end, key_up = nil},
            K_UP_ARROW = {code = 0xC8, key_down = function() return keyboard:typeSymbol("\\^") end, key_up = nil},
            K_DOWN_ARROW = {code = 0xD0, key_down = function() return keyboard:typeSymbol("\\v") end, key_up = nil},

            -- Numpad Keys
            K_NUMPAD_0 = {code = 0x52, key_down = function() return keyboard:typeSymbol("0") end, key_up = nil},
            K_NUMPAD_1 = {code = 0x4F, key_down = function() return keyboard:typeSymbol("1") end, key_up = nil},
            K_NUMPAD_2 = {code = 0x50, key_down = function() return keyboard:typeSymbol("2") end, key_up = nil},
            K_NUMPAD_3 = {code = 0x51, key_down = function() return keyboard:typeSymbol("3") end, key_up = nil},
            K_NUMPAD_4 = {code = 0x4B, key_down = function() return keyboard:typeSymbol("4") end, key_up = nil},
            K_NUMPAD_5 = {code = 0x4C, key_down = function() return keyboard:typeSymbol("5") end, key_up = nil},
            K_NUMPAD_6 = {code = 0x4D, key_down = function() return keyboard:typeSymbol("6") end, key_up = nil},
            K_NUMPAD_7 = {code = 0x47, key_down = function() return keyboard:typeSymbol("7") end, key_up = nil},
            K_NUMPAD_8 = {code = 0x48, key_down = function() return keyboard:typeSymbol("8") end, key_up = nil},
            K_NUMPAD_9 = {code = 0x49, key_down = function() return keyboard:typeSymbol("9") end, key_up = nil},
            K_NUMPAD_SLASH = {code = 0xB5, key_down = function() return keyboard:typeSymbol("/") end, key_up = nil},
            K_NUMPAD_ASTERISK = {code = 0x37, key_down = function() return keyboard:typeSymbol("*") end, key_up = nil},
            K_NUMPAD_SUBTRACT = {code = 0x4A, key_down = function() return keyboard:typeSymbol("-") end, key_up = nil},
            K_NUMPAD_ADD = {code = 0x4E, key_down = function() return keyboard:typeSymbol("+") end, key_up = nil},
            K_NUMPAD_ENTER = {code = 0x9C, key_down = function() return keyboard:typeSymbol("\n") end, key_up = nil},
            K_NUMPAD_LOCK = {code = 0x45, key_down = nil, key_up = nil},
            K_NUMPAD_PERIOD = {code = 0x53, key_down = function() return keyboard:typeSymbol(".") end, key_up = nil},

            -- Japanese Keys
            -- Note these were carried over from OpenOS, I don't own any japanese keys. Do with them as you like.
            K_KEY_KANA = {code = 0x70, key_down = nil, key_up = nil},
            K_KEY_KANJI = {code = 0x94, key_down = nil, key_up = nil},
            K_KEY_CONVERT = {code = 0x79, key_down = nil, key_up = nil},
            K_KEY_NOCONVERT = {code = 0x7B, key_down = nil, key_up = nil},
            K_KEY_YEN = {code = 0x7D, key_down = nil, key_up = nil},
            K_KEY_CIRCUMFLEX = {code = 0x90, key_down = nil, key_up = nil},
            K_KEY_AX = {code = 0x96, key_down = nil, key_up = nil}
        }
        self.keys = keys
    end

return keyboard