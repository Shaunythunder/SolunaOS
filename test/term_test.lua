-- /apps/terminal_test.lua
-- Simple terminal for testing I/O, cursor, and text input with scroll buffer

local io = require("io")
local draw = require("draw")
local scroll_buffer = require("scroll_buffer")
local os = require("os")
local fps = _G.fps or 0.05

local terminal_buffer = scroll_buffer.new()

-- Initial messages
io.writeBuffered(terminal_buffer, "SolunaOS Terminal Test")
io.writeBuffered(terminal_buffer, "Type 'exit' to quit, 'clear' to clear screen")
io.writeBuffered(terminal_buffer, "Test your cursor movement, backspace, delete, etc.")
io.writeBuffered(terminal_buffer, "Terminal will scroll when full")
io.writeBuffered(terminal_buffer, "")

local prompt = "test> "

while true do
    local input = io.read(prompt)
    
    if input == "exit" then
        io.writeBuffered(terminal_buffer, "Goodbye!")
        break
    elseif input == "clear" then
        terminal_buffer:clear()
        draw.clear()
        io.writeBuffered(terminal_buffer, "Screen cleared")
    elseif input == "" then
        io.writeBuffered(terminal_buffer, "(empty input)")
    elseif input == "scroll" then
        -- Test scrolling by adding many lines
        for i = 1, 10 do
            io.writeBuffered(terminal_buffer, "Test line " .. i .. " for scrolling")
        end
    else
        io.writeBuffered(terminal_buffer, "You typed: '" .. input .. "'")
        io.writeBuffered(terminal_buffer, "Length: " .. #input .. " characters")
    end
end