local os = require("os")
local gpu = _G.primary_gpu
local x_max_pos, y_max_pos = gpu.getResolution()
local x_min_pos, y_min_pos = 1, 1 -- Also default position

local cursor = {
    x_pos = 1,
    y_pos = 1,
    x_max_pos = x_max_pos,
    y_max_pos = y_max_pos,
    x_min_pos = x_min_pos,
    y_min_pos = y_min_pos,
    symbol = "█"
}

function cursor:reset()
    self.x_pos = 1
    self.y_pos = 1
    self:updateBoundaries() -- self.x_max_pos, self.y_max_pos
    self.x_min_pos = x_min_pos
    self.y_min_pos = y_min_pos
    self.symbol = "█"
end

function cursor:updateBoundaries()
    self.x_max_pos, self.y_max_pos = gpu.getResolution()
end


function cursor:setSymbol(symbol)
    if type(symbol) ~= "string" or #symbol ~= 1 then
        error("Symbol must be a single character string")
    end
    self.symbol = symbol
end

function cursor:setPosition(x_set_pos, y_set_pos)
    self:updateBoundaries()
    if x_set_pos < self.x_min_pos then
        self.x_pos = self.x_min_pos
    elseif x_set_pos > self.x_max_pos then
        self.x_pos = self.x_max_pos
    else
        self.x_pos = x_set_pos
    end
    if y_set_pos < self.y_min_pos then
        self.y_pos = self.y_min_pos
    elseif y_set_pos > self.y_max_pos then
        self.y_pos = self.y_max_pos
    else
        self.y_pos = y_set_pos
    end
end

function cursor:getPosition()
    return self.x_pos, self.y_pos
end

function cursor:getX()
    return self.x_pos
end

function cursor:getY()
    return self.y_pos
end

function cursor:getSymbol()
    return self.symbol
end

function cursor:getBoundaries()
    return self.x_min_pos, self.y_min_pos, self.x_max_pos, self.y_max_pos
end

function cursor:movePosition(move_x_pos, move_y_pos)
    self:updateBoundaries()
    self.x_pos = self.x_pos + move_x_pos
    self.y_pos = self.y_pos + move_y_pos
    if self.x_pos > self.x_max_pos then
        self.x_pos = self.x_min_pos
        self.y_pos = self.y_pos + 1 -- Wrap to next line
    elseif self.x_pos < self.x_min_pos then
        self.x_pos = self.x_min_pos
    end
    if self.y_pos < self.y_min_pos then
        self.y_pos = self.y_min_pos
    elseif self.y_pos > self.y_max_pos then
        self.y_pos = self.y_max_pos
    end
end

function cursor:show()
    gpu.set(self.x_pos, self.y_pos, self.symbol)
end

function cursor:hide()
    gpu.set(self.x_pos, self.y_pos, " ")
end

function cursor:blink()
    self:show()
    os.sleep(0.5)
    self:hide()
    os.sleep(0.5)
end

function cursor:save()
    self.saved_x = self.x_pos
    self.saved_y = self.y_pos
end

function cursor:restore()
    if self.saved_x == nil or self.saved_y == nil then
        return
    else
        self.x_pos = self.saved_x
        self.y_pos = self.saved_y
    end
end

return cursor