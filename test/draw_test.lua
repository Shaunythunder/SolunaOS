local scrollBuffer = require("scroll_buffer")
local draw = require("draw")              
local os = require("os")
local buffer = scrollBuffer.new()
local gpu = _G.primary_gpu
local fps = _G.fps
local width, height = gpu.getResolution()


local x = 1
local y = 1
while true do
    local fr = math.random(0, 255)
    local fg = math.random(0, 255)
    local fb = math.random(0, 255)
    local forecolor = draw.getRGB(fr, fg, fb)
    local br = math.random(0, 255)
    local bg = math.random(0, 255)
    local bb = math.random(0, 255)
    local backcolor = draw.getRGB(br, bg, bb)
    local end_x = math.random(1, 15)
    local end_y = math.random(1, 15)
    local end_xy
    if end_x > end_y then
        end_xy = end_x
    else
        end_xy = end_y
    end
    local lineweight = math.random(0, end_xy)
    draw.clear()
    gpu.setBackground(backcolor)
    gpu.fill(1, 1, width, height, " ")
    x = x + 1
    if x >= width then
        x = 1
        y = y + 1
    end
    if y >= height then
        y = 1
    end
    os.sleep(fps)
end