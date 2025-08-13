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

function textBuffer:clear()
    self.text = ""
    self.position = 1
end

function textBuffer:terminate()
    self:clear()
    for attribute in pairs(self) do
        self[attribute] = nil -- Clear methods to free up memory
    end
    setmetatable(self, nil)
    collectgarbage()
end

function textBuffer:getLength()
    return #self.text
end

function textBuffer:getText()
    return self.text
end

function textBuffer:getPosition()
    return self.position
end

function textBuffer:setText(new_text)
    self.text = new_text
    self.position = #new_text + 1
end

function textBuffer:prepend(string)
    self.text = string .. self.text
    self.position = #string + 1
end

function textBuffer:append(string)
    self.text = self.text .. string
    self.position = #self.text + 1
end

function textBuffer:insert(string)
    self.text = self.text:sub(1, self.position - 1) .. string .. self.text:sub(self.position)
    self.position = self.position + #string
end

function textBuffer:backspace()
    if self.position > 1 then
        self.text = self.text:sub(1, self.position - 2) .. self.text:sub(self.position)
        self.position = self.position - 1
    end
end

function textBuffer:delete()
    self.text = self.text:sub(1, self.position - 1) .. self.text:sub(self.position + 1)
end

function textBuffer:moveLeft()
    if self.position > 1 then
        self.position = self.position - 1
    end
end

function textBuffer:moveRight()
    if self.position <= #self.text then
        self.position = self.position + 1
    end
end

return textBuffer