-- /lib/core/scroll_buffer.lua
-- Contains scroll and print out history

local gpu = _G.primary_gpu
-- local filesystem = require("filesystem") cannot be used until we have a real hard drive

local scrollBuffer = {}
    scrollBuffer.__index = scrollBuffer

    function scrollBuffer.new()
        local self = setmetatable({}, scrollBuffer)
        self.buffer_lines = {}
        self.visible_lines = {}
        self.visible_max_lines = 60
        self.max_lines = 60
        self.buffer_index = 1
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
        local _, height = gpu.getResolution()
        self.visible_max_lines = height
        self.max_lines = height * 2
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
        local _, height = gpu.getResolution()
        local end_index = #self.buffer_lines - height + 1
        if end_index < 1 then
            end_index = 1
        end
        if self.buffer_index < end_index then
            self.buffer_index = self.buffer_index + 1
            self:updateVisibleBuffer()
        end
    end

    function scrollBuffer:scrollToPosition(y_pos)
        local _, height = gpu.getResolution()
        local end_index = #self.buffer_lines - height + 1
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
        local _, height = gpu.getResolution()
        local end_index = self.buffer_index + height
        for i = self.buffer_index, end_index do
            if self.buffer_lines[i] then
                table.insert(self.visible_lines, self.buffer_lines[i])
            end
        end
    end

    --- Scrolls to the bottom of the buffer and updates visible lines
    function scrollBuffer:scrollToBottom()
        local _, height = gpu.getResolution()
        self.buffer_index = #self.buffer_lines - height + 1
        if self.buffer_index < 1 then
            self.buffer_index = 1
        end
        self:updateVisibleBuffer()
    end

    -- Adds new line to terminal buffer with option logging feature
    ---@param line string
    function scrollBuffer:addLine(line)
        table.insert(self.buffer_lines, line)
        self:updateMaxLines()
        self:removeOldLines()
        self:scrollToBottom()
        if self.logging and self.log_file_path then
            self:exportLine(self.log_file_path, line)
        end
    end

return scrollBuffer


