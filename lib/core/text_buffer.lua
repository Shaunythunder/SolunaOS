-- /lib/core/text_buffer.lua
-- Text storage object for word processors.

local textBuffer = {}
    textBuffer.__index = textBuffer

    function textBuffer.new()
        local self = setmetatable({}, textBuffer)
        self.text = ""
        self.pos = 1
        return self
    end

    -- Removes text buffer object and cleans it up.
    function textBuffer:terminate()
        self:clear()
        for attribute in pairs(self) do
            self[attribute] = nil -- Clear methods to free up memory
        end
        setmetatable(self, nil)
        collectgarbage()
    end

    -- Clears the text buffer
    function textBuffer:clear()
        self.text = ""
        self.pos = 1
    end

    -- Gets the length of the text buffer
    function textBuffer:getLength()
        return #self.text
    end

    -- Gets the text in the buffer
    --- @return string text
    function textBuffer:getText()
        return self.text
    end

    -- Gets the current position in the text buffer
    --- @return number position
    function textBuffer:getPosition()
        return self.pos
    end

    -- Sets the text in the buffer
    --- @param text string
    function textBuffer:setText(text)
        self.text = text
        self.pos = #text + 1
    end

    --- Prepends text to the buffer
    --- @param text string
    function textBuffer:prepend(text)
        self.text = text .. self.text
        self.pos = #text + 1
    end

    --- Appends text to the buffer
    --- @param text string
    function textBuffer:append(text)
        self.text = self.text .. text
        self.pos = #self.text + 1
    end

    --- Inserts text at the current position in the buffer
    --- @param text string
    function textBuffer:insert(text)
        self.text = self.text:sub(1, self.pos - 1) .. text .. self.text:sub(self.pos)
        self.pos = self.pos + #text
    end

    --- Deletes the character before the current position in the buffer
    function textBuffer:backspace()
        if self.pos > 1 then
            self.text = self.text:sub(1, self.pos - 2) .. self.text:sub(self.pos)
            self.pos = self.pos - 1
        end
    end

    --- Deletes the character at the current position in the buffer
    function textBuffer:delete()
        self.text = self.text:sub(1, self.pos - 1) .. self.text:sub(self.pos + 1)
    end

    -- Moves the current position left by one character
    function textBuffer:moveLeft()
        if self.pos > 1 then
            self.pos = self.pos - 1
        end
    end

    --- Moves the current position right by one character
    function textBuffer:moveRight()
        if self.pos <= #self.text then
            self.pos = self.pos + 1
        end
    end

return textBuffer