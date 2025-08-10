-- /boot/boot.lua
-- Bootstraps the SolunaOS environment

do
    _G.OS_VERSION = "SolunaOS v 0.0.1"

    local loadfile = ...
    local BSOD_BLUE = 0x0000FF
    local WHITE = 0xFFFFFF
    local component_invoke = component.invoke
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

    local function errorMessage(msg)
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
        else
            computer.beep(1000, 0.5)
            computer.beep(1000, 0.5)
        end
    end

    --- Get list of boot directory and all files.
    ---@return string[] A list of boot scripts
    local function getBootScripts()
        local scripts = {}
        local filesystem = component.proxy(component.list("filesystem")())
        for filename in filesystem.list("/boot") do
            if filename:match("%.lua$") and filename ~= "boot.lua" then
                table.insert(scripts, "/boot/" .. filename)
            end
        end
        table.sort(scripts)
        return scripts
    end

    --- Run all boot scripts in order.
    local function runBootScripts()
        local ok, scripts = pcall(getBootScripts)
        if not ok then
            errorMessage("Failed to get boot scripts: " .. tostring(scripts))
            return
        end
        for _, script in ipairs(scripts) do
            local chunk, load_error = loadfile(script)
            if not chunk then
                errorMessage("Failed to run boot script " .. script .. ": " .. tostring(load_error))
                while true do computer.pullSignal(1) end
    
            end
            local run, run_error = pcall(chunk)
            if not run then
                errorMessage("Failed to run boot script " .. script .. ": " .. tostring(run_error))
                while true do computer.pullSignal(1) end
            end
        end
    end

    runBootScripts()
end
