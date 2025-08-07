local gpu_addr = component.list("gpu") and component.list("gpu")()
local screen_addr = component.list("screen") and component.list("screen")()
local computer_addr = component.list("computer") and component.list("computer")()

local function welcomeBlit(message)
    if gpu_addr and screen_addr then
                local gpu = component.proxy(gpu_addr)
                gpu.bind(screen_addr)
                local width, height = gpu.getResolution()
                gpu.setBackground(0x000000)
                gpu.setForeground(0xFFFFFF)
                gpu.fill(1, 1, width, height, " ")
                local start_x = math.floor((width - #message) / 2) + 1
                local start_y = math.floor(height / 2)
                gpu.set(start_x, start_y, message)
    end
end

welcomeBlit("Welcome to SolunaOS!!!!!!!")
while true do
    computer.pullSignal(1)
end
