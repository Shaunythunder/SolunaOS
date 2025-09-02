-- /lib/core/scroll_buffer.lua
-- Contains scroll and print out history
-- Also contains file editing capabilities towards the bottom

local draw = require("draw")
local gpu = _G.primary_gpu
local fs = require("filesystem")

local scrollBuffer = {}
    scrollBuffer.__index = scrollBuffer

    function scrollBuffer.new()
        local self = setmetatable({}, scrollBuffer)
        local height = _G.height
        local width = _G.width
        self.buffer_lines = {}
        self.visible_lines = {}
        self.visible_max_lines = 60
        self.max_lines = 60
        self.buffer_index = 1
        self.render_offset = 0
        self.vram_buffer = gpu.allocateBuffer(width, height - 1)
        self.logging = false
        self.log_file_path = nil
        self:updateMaxLines()
        return self
    end

    function scrollBuffer:terminate()
        self:clear()
        gpu.freeBuffer(self.vram_buffer)
        for attribute in pairs(self) do
            self[attribute] = nil -- Clear methods to free up memory
        end
        setmetatable(self, nil)
    end

    function scrollBuffer:clear()
        self.buffer_lines = {}
        self:updateMaxLines()
    end

    --- Sets max visible lines equal to screen height
    function scrollBuffer:updateMaxLines()
        self.visible_max_lines = _G.height
        self.max_lines = _G.height * 2
    end

    function scrollBuffer:getLines()
        return self.buffer_lines
    end

    -- Removes old lines from the buffer if it exceeds max_lines
    function scrollBuffer:removeOldLines()
        while #self.buffer_lines > self.max_lines do
            table.remove(self.buffer_lines, 1)
        end
    end

    function scrollBuffer:scrollUp()
        if self.buffer_index > 1 then
            self.buffer_index = self.buffer_index - 1
            self:updateVisibleBuffer()
        end
    end

    function scrollBuffer:scrollDown()
        local end_index = #self.buffer_lines - _G.height + 1
        if end_index < 1 then
            end_index = 1
        end
        if self.buffer_index < end_index then
            self.buffer_index = self.buffer_index + 1
            self:updateVisibleBuffer()
        end
    end

    function scrollBuffer:scrollToPosition(y_pos)
        local end_index = #self.buffer_lines - _G.height + 1
        if end_index < 1 then
            end_index = 1
        end
        if y_pos < 1 then
            y_pos = 1
        elseif y_pos > end_index then
            y_pos = end_index
        end
        self.buffer_index = y_pos
        self:updateVisibleBuffer()
    end

    function scrollBuffer:getVisibleLines()
        return self.visible_lines
    end

    function scrollBuffer:enableLogging()
        self.logging = true
    end

    function scrollBuffer:disableLogging()
        self.logging = false
    end

    function scrollBuffer:isLoggingEnabled()
        return self.logging
    end

    function scrollBuffer:getLogFilePath()
        return self.log_file_path
    end

    function scrollBuffer:toggleLogging()
        self.logging = not self.logging
    end

    function scrollBuffer:setLogFilePath(file_path)
        if not fs.exists(file_path) then
            local file, err = fs.open(file_path, "w")
            if not file then
                error("Failed to open log file: " .. err)
            end
            file:close()
        end
        self.log_file_path = file_path
    end

    function scrollBuffer:exportHistory(file_path)
        local file, err = fs.open(file_path, "w")
        if not file then
            return false, err
        end
        for _, line in ipairs(self.buffer_lines) do
            file:write(line .. "\n")
        end
        file:close()
        return true
    end

    function scrollBuffer:exportLine(file_path, lines)
        local file, err = fs.open(file_path, "a")
        if not file then
            return false, err
        end
        for _, line in ipairs(lines) do
            file:write(line .. "\n")
        end
        file:close()
        return true
    end

    function scrollBuffer:clearLogFile()
        if self.log_file_path then
            local file, err = fs.open(self.log_file_path, "w")
            if not file then
                return false, err
            end
            file:close()
            return true
        else
            return false, "Log file path not set"
        end
    end

    --- Updates the visible buffer based on the current buffer index
    function scrollBuffer:updateVisibleBuffer()
        gpu.setActiveBuffer(self.vram_buffer)
        local height = _G.height
        local width = _G.width
        self.visible_lines = {}
        local screen_index = 1 - self.render_offset
        self.buffer_index = #self.buffer_lines - _G.height + 2
        local end_index = self.buffer_index + _G.height - 1

        for i = self.buffer_index, end_index do
            if self.buffer_lines[i] then
                table.insert(self.visible_lines, self.buffer_lines[i])
                gpu.fill(1, screen_index, _G.width, 1, " ")
                draw.termText(self.buffer_lines[i], 1, screen_index)
                screen_index = screen_index + 1
            end
        end
        gpu.setActiveBuffer(0)
        gpu.bitblt(0, 1, 1, width, height - 1, self.vram_buffer, 1, 1)
    end

    function scrollBuffer:pushUp()
        self.render_offset = self.render_offset + 1
        self:updateVisibleBuffer()
    end

    function scrollBuffer:pushDown()
        self.render_offset = self.render_offset - 1
        self:updateVisibleBuffer()
    end

    function scrollBuffer:pushReset()
        self.render_offset = 0
        self:updateVisibleBuffer()
    end

    --- Scrolls to the bottom of the buffer and updates visible lines
    function scrollBuffer:scrollToBottom()
        self.buffer_index = #self.buffer_lines - _G.height
        if self.buffer_index < 1 then
            self.buffer_index = 1
        end
        self:updateVisibleBuffer()
    end

    function scrollBuffer:scrollToTop()
        self.buffer_index = 1
        self:updateVisibleEditor()
    end

    -- Adds new line to terminal buffer with option logging feature
    ---@param raw_line string
    ---@param setting string|nil scroll to "editor" or "terminal". Defaults to "terminal"
    ---@return number y_home_increment
    function scrollBuffer:addLine(raw_line, setting)
        local setting = setting or "terminal"
        if setting ~= "terminal" and setting ~= "editor" then
            error("Invalid setting for addLine: " .. tostring(setting) .. "must use 'terminal', 'editor' or leave nil.")
        end
        local lines_added = 1
        local wrap = 0
        local lines = {}
        for actual_line in raw_line:gmatch("([^\n]*)\n?") do
            table.insert(lines, actual_line)
        end

        for _, line in ipairs(lines) do
            while #line > 0 do
                if #line > _G.width then
                    local wrapped_line = line:sub(1, _G.width)
                    table.insert(self.buffer_lines, wrapped_line)
                    line = line:sub(_G.width + 1)
                    lines_added = lines_added + 1
                    wrap = wrap + 1
                else
                    table.insert(self.buffer_lines, line)
                    break
                end
            end
        end
        self:updateMaxLines()
        self:removeOldLines()

        if setting == "editor" then
            self:scrollToTop()
        elseif setting == "terminal" then
            self:scrollToBottom()
        end
        if self.logging and self.log_file_path then
            self:exportLine(self.log_file_path, lines)
        end
        lines_added = lines_added - wrap
        return lines_added
    end

    --+++++++++++++++++++++++++ File Editing Capabilities +++++++++++++++++++++++++++++++++++++

    function scrollBuffer:fileEditorMode()
        local height = _G.height
        self.cursor_x = 1
        self.cursor_y = 1
        self.buffer_lines = {}
        self.visible_lines = {}
        self.max_lines = math.huge
        self.buffer_index = 1
        self.visible_max_lines = height
    end

    function scrollBuffer:loadFromFile(abs_path)
        if not fs.exists(abs_path) then
            return false, "File does not exist"
        end
        local file, err = fs.open(abs_path, "r")
        if not file then
            return false, "Failed to open file: " .. err
        end
        self:clear()

        local content = ""
        local chunk, err
        repeat
            chunk, err = fs.read(file, 4098)
            if chunk and chunk ~= "" then
                content = content .. chunk
            end
        until not chunk or chunk == "" or err
        
        self:addLine(content, "editor")
        
        fs.close(file)
        return true
    end

    function scrollBuffer:saveToFile(abs_path)
        local content
        for i, line in ipairs(self.buffer_lines) do
            if i < #self.buffer_lines then
                content = (content or "") .. line .. "\n"
            else
                content = (content or "") .. line
            end
        end
        local file, err = fs.open(abs_path, "w")
        if not file then
            return false, "Failed to open file for writing: " .. err
        end
        fs.write(file, content)
        fs.close(file)
        return true
    end

    function scrollBuffer:setLine(y_pos, content)
        if y_pos < 1 or y_pos > #self.buffer_lines then
            return false, "Line number out of range"
        end
        self.buffer_lines[y_pos] = content
        self:updateVisibleBuffer()
        return true
    end

    function scrollBuffer:insertLine(y_pos, content)
        if y_pos < 1 or y_pos > #self.buffer_lines + 1 then
            return false, "Line number out of range"
        end
        table.insert(self.buffer_lines, y_pos, content)
        self:updateVisibleBuffer()
        return true
    end

    function scrollBuffer:deleteLine(y_pos)
        if y_pos < 1 or y_pos > #self.buffer_lines then
            return false, "Line number out of range"
        end
        table.remove(self.buffer_lines, y_pos)
        self:updateVisibleBuffer()
        return true
    end

    function scrollBuffer:getCursorPosition()
        return self.cursor_x, self.cursor_y
    end

    function scrollBuffer:setCursorPosition(x_pos, y_pos)
        local height = _G.height
        if x_pos < 1 then
            x_pos = 1
        end
        if y_pos < 1 then
            y_pos = 1
        end
        if y_pos > height - 2 then
            y_pos = height - 2
        end
        if y_pos > #self.buffer_lines then
            y_pos = #self.buffer_lines
        end
        local line = self.buffer_lines[y_pos] or ""
        local line_length = #line
        if x_pos > line_length + 1 then
            x_pos = line_length + 1
        end
        self.cursor_x = x_pos
        self.cursor_y = y_pos
        self:updateVisibleEditor()
    end

    function scrollBuffer:moveCursorLeft()
        if self.cursor_x > 1 then
            self.cursor_x = self.cursor_x - 1
        elseif self.cursor_y > 1 then
            self.cursor_y = self.cursor_y - 1
            self.cursor_x = #self.buffer_lines[self.cursor_y] + 1
        end
        self:setCursorPosition(self.cursor_x, self.cursor_y)
    end

    function scrollBuffer:moveCursorRight()
        local current_line = self.buffer_lines[self.cursor_y] or ""
        
        if self.cursor_x <= #current_line then
            self.cursor_x = self.cursor_x + 1
        elseif self.cursor_y < #self.buffer_lines then
            self.cursor_y = self.cursor_y + 1
            self.cursor_x = 1
        end
        self:setCursorPosition(self.cursor_x, self.cursor_y)
    end

    function scrollBuffer:moveCursorDown()
        local height = _G.height
        if self.cursor_y < height - 2 then
            self.cursor_y = self.cursor_y + 1
        elseif self.buffer_index < #self.buffer_lines then
            self.buffer_index = self.buffer_index + 1
        end
        self:setCursorPosition(self.cursor_x, self.cursor_y)
    end

    function scrollBuffer:moveCursorUp()
        if self.cursor_y > 1 then
            self.cursor_y = self.cursor_y - 1
        elseif self.buffer_index > 1 then
            self.buffer_index = self.buffer_index - 1
        end
        self:setCursorPosition(self.cursor_x, self.cursor_y)
    end

    function scrollBuffer:updateVisibleEditor()
        gpu.setActiveBuffer(self.vram_buffer)
        draw.clear()
        local height = _G.height
        local width = _G.width
        self.visible_lines = {}
        local screen_index = 1
        local end_index = self.buffer_index + _G.height - 3

        for line = self.buffer_index, end_index do
            if self.buffer_lines[line] then
                table.insert(self.visible_lines, self.buffer_lines[line])
                draw.singleLineText(self.buffer_lines[line], 1, screen_index)
                screen_index = screen_index + 1
            end
        end
        gpu.setActiveBuffer(0)
        gpu.bitblt(0, 1, 1, width, height - 2, self.vram_buffer, 1, 1)
    end

    function scrollBuffer:updateSingleLine(y_pos)
        local width = _G.width
        local y_pos = y_pos or self.cursor_y
        local line_to_update = y_pos + self.buffer_index - 1
        local string = self.buffer_lines[line_to_update] or ""
        draw.singleLineText(string, 1, y_pos)
    end

    function scrollBuffer:insertCharacter(char)
        local width = _G.width
        local line_to_change = self.cursor_y + self.buffer_index - 1
        local line = self.buffer_lines[line_to_change] or ""
        local before = line:sub(1, self.cursor_x - 1)
        local after = line:sub(self.cursor_x)
        local new_line = before .. char .. after

        local cursor_increase = 1
        if char == "    " then
            cursor_increase = 4
        end

        if #new_line > width then
            local wrapped_line = new_line:sub(1, width)
            local overflow = new_line:sub(width + 1)
            local next_line = self.buffer_lines[line_to_change + 1] or ""

            self.buffer_lines[line_to_change] = wrapped_line
            self.buffer_lines[line_to_change + 1] = overflow .. next_line

            if self.cursor_x > width then
                self.cursor_y = self.cursor_y + 1
                self.cursor_x = self.cursor_x - width + cursor_increase
            else
                self.cursor_x = self.cursor_x + cursor_increase
            end

            self:updateVisibleEditor()
        else
            self.buffer_lines[line_to_change] = new_line
            self.cursor_x = self.cursor_x + cursor_increase
            self:updateSingleLine()
        end
    end

    function scrollBuffer:backspace()
        local line_to_change = self.cursor_y + self.buffer_index - 1
        if self.cursor_x > 1 then
            local line = self.buffer_lines[line_to_change] or ""
            self.buffer_lines[line_to_change] = line:sub(1, self.cursor_x - 2) .. line:sub(self.cursor_x)
            self.cursor_x = self.cursor_x - 1
        elseif self.cursor_y > 1 then
            local current_line = self.buffer_lines[line_to_change] or ""
            local previous_line = self.buffer_lines[line_to_change - 1] or ""

            self.buffer_lines[line_to_change - 1] = previous_line .. current_line
            table.remove(self.buffer_lines, line_to_change)
            self.cursor_x = #previous_line + 1
            self.cursor_y = self.cursor_y - 1
        end
        self:updateVisibleEditor()
    end

    function scrollBuffer:delete()
        local line_to_change = self.cursor_y + self.buffer_index - 1
        local line = self.buffer_lines[line_to_change] or ""
        if self.cursor_x <= #line then
            self.buffer_lines[line_to_change] = line:sub(1, self.cursor_x - 1) .. line:sub(self.cursor_x + 1)
        elseif line_to_change < #self.buffer_lines then
            local next_line = self.buffer_lines[line_to_change + 1] or ""
            self.buffer_lines[line_to_change] = line .. next_line
            table.remove(self.buffer_lines, line_to_change + 1)
        end
        self:updateVisibleEditor()
    end

    function scrollBuffer:newLine()
        local line_to_change = self.cursor_y + self.buffer_index - 1
        local line = self.buffer_lines[line_to_change] or ""
        local before = line:sub(1, self.cursor_x - 1)
        local after = line:sub(self.cursor_x)
        self.buffer_lines[line_to_change] = before
        table.insert(self.buffer_lines, line_to_change + 1, after)
        self.cursor_y = self.cursor_y + 1
        self.cursor_x = 1
        self:updateVisibleEditor()
    end

    function scrollBuffer:findText(search_term)
        if not search_term or search_term == "" then
            return {}
        end
        local results = {}
        for y_pos, line in ipairs(self.buffer_lines) do
            local start_pos = 1

            while true do
                local found_pos = line:find(search_term, start_pos, true)
                if found_pos then
                    table.insert(results, {line = y_pos, column = found_pos})
                    start_pos = found_pos + #search_term
                else
                    break
                end
            end
        end
        return results
    end

    function scrollBuffer:highlightText(search_term, search_results, iterator)
        local BLACK = 0x000000
        local WHITE = 0xFFFFFF
        local GREY = 0x808080
        for i, result in ipairs(search_results) do
            local screen_line = result.line - self.buffer_index + 1
            local screen_column = result.column

            if screen_line >= 1 and screen_line <= _G.height - 2 then
                if i == iterator then
                    draw.highlightText(search_term, screen_column, screen_line, WHITE, GREY)
                else
                    draw.highlightText(search_term, screen_column, screen_line, BLACK, WHITE)
                end
            end
        end
    end

    function scrollBuffer:scrollToText(search_results, iterator)
        if iterator > #search_results then
            iterator = #search_results
        end
        if #search_results > 0 then
            local result = search_results[iterator]

            self.buffer_index = result.line - 8
            if self.buffer_index < 1 then
                self.buffer_index = 1
            end
            self.cursor_y = result.line - self.buffer_index + 1
            self.cursor_x = result.column
            self:updateVisibleEditor()
        end
    end

    function scrollBuffer:getTotalCharacters()
        local size = 0
        for _, line in ipairs(self.buffer_lines) do
            size = size + #line
        end
        return size
    end

    function scrollBuffer:getTotalLines()
        return #self.buffer_lines
    end

    function scrollBuffer:getCurrentLine()
        return self.cursor_y + self.buffer_index - 1
    end

    function scrollBuffer:getCurrentColumn()
        return self.cursor_x
    end

    function scrollBuffer:getFileSize()
        local size = self:getTotalCharacters()
        if size < 1024 then
            return size .. " B"
        elseif size < 1024 * 1024 then
            size = size / 1024
            return string.format("%.2f KB", size)
        else
            size = size / (1024 * 1024)
            return string.format("%.2f MB", size)
        end
    end

return scrollBuffer


