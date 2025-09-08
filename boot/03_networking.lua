-- /boot/03_networking.lua

local function generateRandomIP()
    local ip = {}
    for i = 1, 4 do
        table.insert(ip, math.random(1, 254)) -- Avoid 0 and 255 for realism
    end
    return table.concat(ip, ".")
end

local system_ip = generateRandomIP()
_G.SYSTEM_IP = system_ip