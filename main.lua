-- Pass hardware_registers to main from init.lua
local hardware_registers = ...

    --- Displays an error message on the screen.
    --- @param msg string - The error message to display.
    --- @return nil
    local function errorMessage(msg)
        local gpu = hardware_registers.gpu and hardware_registers.gpu[1].proxy
        local screen = hardware_registers.screen and hardware_registers.screen[1].address
        local BSOD_BLUE = 0x0000FF
        local WHITE = 0xFFFFFF
        if gpu and screen then
            gpu.bind(screen)
            local width, height = gpu.getResolution()
            gpu.setBackground(BSOD_BLUE)
            gpu.setForeground(WHITE)
            gpu.fill(1, 1, width, height, " ")
            local start_x = math.floor((width - #msg) / 2) + 1
            local start_y = math.floor(height / 2)
            gpu.set(start_x, start_y, msg)
            computer.beep(1000, 0.5)
            computer.beep(1000, 0.5)
        else
            error("GPU or screen not found")
        end
    end

    errorMessage("main.lua paoghvuesiraphgbuuripeashgufioe")
    while true do computer.pullSignal() end