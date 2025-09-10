-- /lib/core/io.lua
-- This module provides functions for input and output operations.

local cursor = _G.cursor
local text_buffer = require("text_buffer")
local draw = require("draw")
local event = _G.event

local terminal = {}

    -- Writes output directly to the terminal at the current cursor position.
    --- @param ... any
    function terminal.write(...)
        local args = {...}
        local output = table.concat(args, " ")
        local increment = draw.termText(output, 1)
        cursor:setHomeY(cursor:getHomeY() + increment)
        cursor:setPosition(1, cursor:getHomeY())
    end

    -- Writes output to the scroll buffer and updates cursor position.
    --- @param scroll_buffer table
    --- @param ... any
    function terminal.writeBuffered(scroll_buffer, ...)
        local args = {...}
        local height = _G.height
        local output = table.concat(args, " ")
        local increment = scroll_buffer:addLine(output)
        
        local visible_lines = scroll_buffer:getVisibleLines()
        local cursor_y = math.min(#visible_lines, height) + increment
        if cursor_y > height then
            cursor_y = height
        end
        scroll_buffer:pushReset()
        cursor:setHomeY(cursor_y)
        cursor:setPosition(1, cursor_y)
    end

    --- Reads input from the user with an optional prompt.
    --- @param prompt string|nil
    --- @return string input
    function terminal.read(prompt)
        local shell = _G.shell
        if shell then
            shell:resetHistoryIndex()
        end
        local scroll_buffer = _G.scroll_buffer
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