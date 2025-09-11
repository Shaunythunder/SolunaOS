local unicode = require("unicode")
local sys = require("system")
local gpu = _G.primary_gpu
local screen_width = _G.width
local screen_height = _G.height

local names = {}
for k, v in pairs(unicode) do
    table.insert(names, k)
end
table.sort(names)

local col_width = 18
local cols = math.floor(screen_width / col_width)
local rows = math.ceil(#names / cols)

gpu.setBackground(0x000000)
gpu.setForeground(0xFFFFFF)
gpu.fill(1, 1, screen_width, screen_height, " ")

for i, name in ipairs(names) do
    local col = ((i - 1) % cols)
    local row = math.floor((i - 1) / cols)
    local x = 1 + col * col_width
    local y = 1 + row
    local char = unicode[name]
    gpu.set(x, y, string.format("%-14s %s", name, char))
end

sys.freeze()