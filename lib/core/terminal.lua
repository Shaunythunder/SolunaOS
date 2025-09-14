-- /lib/core/io.lua
-- This module provides functions for input and output operations.

local text_buffer = require("text_buffer")
local draw = require("draw")
local event = _G.event

local terminal = {}

-- Writes output to the scroll buffer and updates cursor position.
--- @param height number|nil
--- @param cursor table|nil
--- @param scroll_buffer table|nil
--- @param ... any
function terminal.write(height, cursor, scroll_buffer, ...)
    local args = {...}
    local h = height or _G.height
    local cursor = cursor or _G.cursor
    local scroll_buffer = scroll_buffer or _G.scroll_buffer

    local output = table.concat(args, " ")
    local increment = scroll_buffer:addLine(output)
    local visible_lines = scroll_buffer:getVisibleLines()
    local cursor_y = math.min(#visible_lines, h) + increment
    if cursor_y > h then
        cursor_y = h
    end
    scroll_buffer:pushReset()
    cursor:setHomeY(cursor_y)
    cursor:setPosition(1, cursor_y)
end

--- Reads input from the user with an optional prompt.
--- @param prompt string|nil
--- @param width number|nil
--- @param cursor table|nil
--- @param scroll_buffer table|nil
--- @param shell table|nil
--- @return string input
function terminal.read(prompt, width, cursor, scroll_buffer, shell)
    local width = width or _G.width
    local shell = shell or _G.shell
    local scroll_buffer = scroll_buffer or _G.scroll_buffer
    local cursor = cursor or _G.cursor

    if shell then
        shell:resetHistoryIndex()
    end
    local prepend_text = prompt or ""
    draw.termText(prepend_text, 1)
    cursor:setPosition(#prepend_text + 1, cursor:getHomeY())
    local input_buffer = text_buffer.new()
    while true do
        local char
        local output
        while char == nil do
            cursor:show()
            output = event:listen(0.5)
            if output ~= nil and type(output) == "string" then
                char = output
                break
            end
            cursor:hide()
            output = event:listen(0.5)
            if output ~= nil and type(output) == "string" then
                char = output
                break
            end
        end
        if char == "\n" then
            cursor:hide()
            local string = input_buffer:getText()
            return string
        elseif char == "pgup" then
            scroll_buffer:scrollUp()
        elseif char == "pgdn" then
            scroll_buffer:scrollDown()
        elseif char == "\t" then
            input_buffer:insert("    ")
        elseif char == "\b" then
            input_buffer:backspace()
        elseif char == "del" then
            input_buffer:delete()
        elseif char == "<-" then
            input_buffer:moveLeft()
        elseif char == "->" then
            input_buffer:moveRight()
        elseif char == "\\^" then
            if shell then
                shell.cmd_hist_index = shell.cmd_hist_index - 1
                local history_line = shell:getHistoryLine(shell.cmd_hist_index)
                if history_line then
                    input_buffer:setText(history_line)
                else
                    shell.cmd_hist_index = shell.cmd_hist_index + 1
                end
            end
        elseif char == "\\v" then
            if shell then
                shell.cmd_hist_index = shell.cmd_hist_index + 1
                local history_line = shell:getHistoryLine(shell.cmd_hist_index)
                if history_line then
                    input_buffer:setText(history_line)
                else
                    input_buffer:setText("")
                end
                if shell.cmd_hist_index > #shell.cmd_hist then
                    shell.cmd_hist_index = #shell.cmd_hist + 1
                end
            end
        elseif #char == 1 then
            input_buffer:insert(char)
        end
        local string = prepend_text .. input_buffer:getText()
        draw.termText(string, 1)
        local cursor_x = (#prepend_text + input_buffer:getPosition()) % (width)
        local cursor_y = cursor:getHomeY() + math.floor((#prepend_text + input_buffer:getPosition() - 1) / width)
        cursor:setPosition(cursor_x, cursor_y)
    end
end

return terminal