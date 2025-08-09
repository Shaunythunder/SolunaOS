-- SolunaOS EEPROM BIOS v1.0
-- Compatible with OpenOS
-- This file is responsible for booting the system by loading the init.lua

local BSOD_BLUE = 0x0000FF
local WHITE = 0xFFFFFF
local BLACK = 0x000000
local init

do
    local component_invoke = component.invoke
    local eeprom = component.list("eeprom")()
    local screen = component.list("screen")()
    local gpu = component.list("gpu")()

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

    --- Gets EEPROM data (boot address)
    --- @return string|nil - boot address or nil if not set
    computer.getBootAddress = function()
        return boot_invoke(eeprom, "getData")
    end

    --- Sets EEPROM data (boot address)
    --- @param address string|nil - address to set or nil to clear
    computer.setBootAddress = function(address)
        return boot_invoke(eeprom, "setData", address)
    end

    --- Attempts to load hardware components on the given address.
    --- once init.lua is found.
    --- @param address string - component address
    local function tryLoadFrom(address)
        local handle, reason = boot_invoke(address, "open", "/init.lua")
        if not handle then
            return nil, reason
        end
        local buffer = ""
        repeat
            local data, reason = boot_invoke(address, "read", handle, 4096)
            if not data and reason then
            return nil, reason
            end
            buffer = buffer .. (data or "")
        until not data
            boot_invoke(address, "close", handle)
            return load(buffer, "=init")
    end

    --- Displays an error message on the screen.
    --- @param msg string - The error message to display.
    --- @return nil
    function errorMessage(msg)
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

    -- Initial GPU setup
    boot_invoke(gpu, "bind", screen)

    if not gpu or not screen then
        boot_invoke(computer, "beep", 1000, 0.4)
        boot_invoke(computer, "beep", 1000, 0.4)
        return
    end

    -- Search for a bootable medium and load init.lua from it.
    -- Test if loadable components are
    local reason
    if computer.getBootAddress() then
        init, reason = tryLoadFrom(computer.getBootAddress())
    end
    if not init then
        computer.setBootAddress()
        for address in component.list("filesystem") do
            init, reason = tryLoadFrom(address)
            if init then
                computer.setBootAddress(address)
                break
            end
        end
    end

    if not init then
        errorMessage("No bootable medium found" .. (reason and (": " .. tostring(reason)) or ""))
        while true do
            computer.pullSignal(1)
        end
    end
end

if init then
    computer.beep(1000, 0.2)
    local ok, err = pcall(init)
    if not ok then
        errorMessage("init.lua error: " .. tostring(err))
        while true do
            computer.pullSignal(1)
        end
    end
end