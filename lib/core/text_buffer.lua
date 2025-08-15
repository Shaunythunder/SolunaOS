-- /lib/core/text_buffer.lua
-- Text storage object for word processors.

local textBuffer = {}
    textBuffer.__index = textBuffer

    function textBuffer.new()
        local self = setmetatable({}, textBuffer)
        self.text = ""
        self.position = 1
        return self
    end

    -- Removes text buffer object and cleans it up.
    --- @return nil
    function textBuffer:terminate()
        self:clear()
        for attribute in pairs(self) do
            self[attribute] = nil -- Clear methods to free up memory
        end
        setmetatable(self, nil)
        collectgarbage()
    end

    -- Clears the text buffer
    --- @return nil
    function textBuffer:clear()
        self.text = ""
        self.position = 1
    end

    -- Gets the length of the text buffer
    --- @return number length
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
        return self.position
    end

    -- Sets the text in the buffer
    --- @param new_text string text to set
    function textBuffer:setText(new_text)
        self.text = new_text
        self.position = #new_text + 1
    end

    --- Prepends text to the buffer
    --- @param string string text to prepend
    function textBuffer:prepend(string)
        self.text = string .. self.text
        self.position = #string + 1
    end

    --- Appends text to the buffer
    --- @param string string text to append
    function textBuffer:append(string)
        self.text = self.text .. string
        self.position = #self.text + 1
    end

    --- Inserts text at the current position in the buffer
    --- @param string string text to insert
    function textBuffer:insert(string)
        self.text = self.text:sub(1, self.position - 1) .. string .. self.text:sub(self.position)
        self.position = self.position + #string
    end

    --- Deletes the character before the current position in the buffer
    --- @return nil
    function textBuffer:backspace()
        if self.position > 1 then
            self.text = self.text:sub(1, self.position - 2) .. self.text:sub(self.position)
            self.position = self.position - 1
        end
    end

    --- Deletes the character at the current position in the buffer
    --- @return nil
    function textBuffer:delete()
        self.text = self.text:sub(1, self.position - 1) .. self.text:sub(self.position + 1)
    end

    -- Moves the current position left by one character
    --- @return nil
    function textBuffer:moveLeft()
        if self.position > 1 then
            self.position = self.position - 1
        end
    end

    --- Moves the current position right by one character
    --- @return nil
    function textBuffer:moveRight()
        if self.position <= #self.text then
            self.position = self.position + 1
        end
    end

return textBuffer