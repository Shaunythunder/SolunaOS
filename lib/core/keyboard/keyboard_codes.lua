--/lib/core/keyboard/keyboard_codes.lua
-- Contains hexadecimal codes for keyboard input handling.

local keyboard_codes = {
    -- Function keys
    KEY_F1 = 0x3B,
    KEY_F2 = 0x3C,
    KEY_F3 = 0x3D,
    KEY_F4 = 0x3E,
    KEY_F5 = 0x3F,
    KEY_F6 = 0x40,
    KEY_F7 = 0x41,
    KEY_F8 = 0x42,
    KEY_F9 = 0x43,
    KEY_F10 = 0x44,
    KEY_F11 = 0x57,
    KEY_F12 = 0x58,
    KEY_F13 = 0x64,
    KEY_F14 = 0x65,
    KEY_F15 = 0x66,
    KEY_F16 = 0x67,
    KEY_F17 = 0x68,
    KEY_F18 = 0x69,
    KEY_F19 = 0x71,

    -- Number Keys
    NUM_1 = 0x02,
    NUM_2 = 0x03,
    NUM_3 = 0x04,
    NUM_4 = 0x05,
    NUM_5 = 0x06,
    NUM_6 = 0x07,
    NUM_7 = 0x08,
    NUM_8 = 0x09,
    NUM_9 = 0x0A,
    NUM_0 = 0x0B,

    -- Operators
    KEY_SUBTRACT = 0x0C,
    KEY_EQUAL = 0x0D,
    KEY_BKSPACE = 0x0E,
    KEY_TAB = 0x0F,
    KEY_CAPSLOCK = 0x3A,
    KEY_LSHIFT = 0x2A,
    KEY_RSHIFT = 0x36,
    KEY_LCTRL = 0x1D,
    KEY_RCTRL = 0x9D,
    KEY_LALT = 0x38,
    KEY_RALT = 0xB8,
    KEY_SPACE = 0x39,
    KEY_ENTER = 0x1C,
    KEY_PRT_SCR = 0x00,
    KEY_SCROLL_LOCK = 0x46,
    KEY_PAUSE_BREAK = 0x05,
    KEY_INSERT = 0xD2,
    KEY_HOME = 0xC7,
    KEY_PGUP = 0xC9,
    KEY_DEL = 0xD3,
    KEY_END = 0xCF,
    KEY_PGDN = 0xD1,

    -- Letter Keys
    KEY_A = 0x1E,
    KEY_B = 0x30,
    KEY_C = 0x2E,
    KEY_D = 0x20,
    KEY_E = 0x12,
    KEY_F = 0x21,
    KEY_G = 0x22,
    KEY_H = 0x23,
    KEY_I = 0x17,
    KEY_J = 0x24,
    KEY_K = 0x25,
    KEY_L = 0x26,
    KEY_M = 0x32,
    KEY_N = 0x31,
    KEY_O = 0x18,
    KEY_P = 0x19,
    KEY_Q = 0x10,
    KEY_R = 0x13,
    KEY_S = 0x1F,
    KEY_T = 0x14,
    KEY_U = 0x16,
    KEY_V = 0x2F,
    KEY_W = 0x11,
    KEY_X = 0x2D,
    KEY_Y = 0x15,
    KEY_Z = 0x2C,

    -- Special Characters
    KEY_GRAVE_ACCENT = 0x29,
    KEY_SEMICOLON = 0x27,
    KEY_COMMA = 0x33,
    KEY_PERIOD = 0x34,
    KEY_SLASH = 0x35,
    KEY_BACKSLASH = 0x2B,
    KEY_LEFT_BRACKET = 0x1A,
    KEY_RIGHT_BRACKET = 0x1B,
    KEY_APOSTROPHE = 0x28,

    -- Navigation Keys
    KEY_LEFT_ARROW = 0xCB,
    KEY_RIGHT_ARROW = 0xCD,
    KEY_UP_ARROW = 0xC8,
    KEY_DOWN_ARROW = 0xD0,

    -- Numpad Keys
    NUMPAD_0 = 0x52,
    NUMPAD_1 = 0x4F,
    NUMPAD_2 = 0x50,
    NUMPAD_3 = 0x51,
    NUMPAD_4 = 0x4B,
    NUMPAD_5 = 0x4C,
    NUMPAD_6 = 0x4D,
    NUMPAD_7 = 0x47,
    NUMPAD_8 = 0x48,
    NUMPAD_9 = 0x49,
    NUMPAD_SLASH = 0xB5,
    NUMPAD_ASTERISK = 0x37,
    NUMPAD_SUBTRACT = 0x4A,
    NUMPAD_ADD = 0x4E,
    NUMPAD_ENTER = 0x9C,
    NUMPAD_LOCK = 0x45,
    NUMPAD_PERIOD = 0x53,

    -- Japanese Keys
    -- Note these were carried over from OpenOS, I don't own any japanese keys. Cannot test.
    KEY_KANA = 0x70,
    KEY_KANJI = 0x94,
    KEY_CONVERT = 0x79,
    KEY_NOCONVERT = 0x7B,
    KEY_YEN = 0x7D,
    KEY_CIRCUMFLEX = 0x90,
    KEY_AX = 0x96

}

local input_look_up_table = {}

for key, value in pairs(keyboard_codes) do
    input_look_up_table[value] = key
end

return {keyboard_codes,
        input_look_up_table
        }