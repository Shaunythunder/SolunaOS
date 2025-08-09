-- Pass hardware_registers to main from init.lua
local hardware_registers = ...

local component_invoke = component.invoke

--- Safely invoke a method from component. Handles errors.
---@param address string - component address
---@param method string - method name to invoke
---@param ... any -- method arguments for component ("gpu" for example).
local function boot_invoke(address, method, ...)
    local result = table.pack(pcall(component_invoke, address, method, ...))
    if not result[1] then
        return nil, result[2]
    else
        return table.unpack(result, 2, result.n)
    end
end

--- Displays an error message on the screen.
--- @param msg string - The error message to display.
--- @return nil
function errorMessage(msg)
    local gpu = hardware_registers.gpu
    local screen = hardware_registers.screen
    local BSOD_BLUE = 0x0000FF
    local WHITE = 0xFFFFFF
    if gpu and screen then
        boot_invoke(gpu, "bind", screen)
        local width, height = boot_invoke(gpu, "getResolution")
        boot_invoke(gpu, "setBackground", BSOD_BLUE)
        boot_invoke(gpu, "setForeground", WHITE)
        boot_invoke(gpu, "fill", 1, 1, width, height, " ")
        local start_x = math.floor((width - #msg) / 2) + 1
        local start_y = math.floor(height / 2)
        boot_invoke(gpu, "set", start_x, start_y, msg)
        computer.beep(1000, 0.5)
        computer.beep(1000, 0.5)
    end
end

errorMessage("SolunaOS main.lua loaded successfullfeafeagsk vgbujjuhygetswazdsxch fjvkujyuhy")
while true do computer.pullSignal() end