-- /lib/core/scroll_buffer.lua
-- Contains scroll and print out history

local draw = require("draw")
local gpu = _G.primary_gpu
local filesystem = require("filesystem")

local scrollBuffer = {}
    scrollBuffer.__index = scrollBuffer

    function scrollBuffer.new()
        local self = setmetatable({}, scrollBuffer)
        self.buffer_lines = {}
        self.visible_lines = {}
        self.visible_max_lines = 60
        self.max_lines = 60
        self.buffer_index = 1
        self.render_offset = 0
        self.logging = false
        self.log_file_path = nil
        self:updateMaxLines()
        return self
    end

    function scrollBuffer:terminate()
        self:clear()
        for attribute in pairs(self) do
            self[attribute] = nil -- Clear methods to free up memory
        end
        setmetatable(self, nil)
        collectgarbage()
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
        if not filesystem.exists(file_path) then
            local file, err = filesystem.open(file_path, "w")
            if not file then
                error("Failed to open log file: " .. err)
            end
            file:close()
        end
        self.log_file_path = file_path
    end

    function scrollBuffer:exportHistory(file_path)
        local file, err = filesystem.open(file_path, "w")
        if not file then
            return false, err
        end
        for _, line in ipairs(self.buffer_lines) do
            file:write(line .. "\n")
        end
        file:close()
        return true
    end

    function scrollBuffer:exportLine(file_path, line)
        local file, err = filesystem.open(file_path, "a")
        if not file then
            return false, err
        end
        file:write(line .. "\n")
        file:close()
        return true
    end

    function scrollBuffer:clearLogFile()
        if self.log_file_path then
            local file, err = filesystem.open(self.log_file_path, "w")
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
    end

    function scrollBuffer:pushUp()
        self.render_offset = self.render_offset + 1
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

    -- Adds new line to terminal buffer with option logging feature
    ---@param line string
    ---@return number y_home_increment
    function scrollBuffer:addLine(line)
        local lines_added = 1
        local wrap = 0

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
        self:updateMaxLines()
        self:removeOldLines()
        self:scrollToBottom()
        if self.logging and self.log_file_path then
            self:exportLine(self.log_file_path, line)
        end
        lines_added = lines_added - wrap
        return lines_added
    end

return scrollBuffer


