-- /boot/boot.lua
-- Bootstraps the SolunaOS environment

do
    local hardware_registers, loadfile = ...

    _G.OS_NAME= "SolunaOS"
    _G.OS_VERSION = "0.14.21"
    _G.hardware_registers = hardware_registers
    _G.BOOT_ADDRESS = computer.getBootAddress()
    _G.OS_FILESYSTEM = component.proxy(_G.BOOT_ADDRESS)
    _G.primary_gpu = hardware_registers.gpu and hardware_registers.gpu[1].proxy
    _G.primary_screen_addr = hardware_registers.screen and hardware_registers.screen[1].address

    local BSOD_BLUE = 0x0000FF
    local WHITE = 0xFFFFFF

    --- Prints Blue Screen of Death message to screen
    --- @param msg string The message to display
    --- @return nil
    _G.errorMessage = function(msg)
        local gpu = _G.primary_gpu
        local screen_addr = _G.primary_screen_addr
        if gpu and screen_addr then
            gpu.bind(screen_addr)
            local width, height = gpu.getResolution()
            gpu.setBackground(BSOD_BLUE)
            gpu.setForeground(WHITE)
            gpu.fill(1, 1, width, height, " ")

            local lines = {}
            for line in msg:gmatch("[^\n]+") do
                while #line > width do
                    local wrap_line = line:sub(1, width)
                    line = line:sub(width + 1)
                    table.insert(lines, wrap_line)
                end
                table.insert(lines, line)
            end
            local start_y = math.floor((height - #lines) / 2) + 1
            for pos, line in ipairs(lines) do
                local start_x = math.floor((width - #line) / 2) + 1
                gpu.set(start_x, start_y + pos - 1, line)
            end
            computer.beep(1000, 0.5)
            computer.beep(1000, 0.5)
            while true do
                computer.pullSignal(1)
            end
        else
            computer.beep(1000, 0.5)
            computer.beep(1000, 0.5)
        end
    end

    --- Get list of boot directory and all files.
    ---@return string[] A list of boot scripts
    local function getBootScripts()
        local scripts = {}
        local boot_addr = _G.BOOT_ADDRESS
        local filesystem = _G.OS_FILESYSTEM
        for _, filename in ipairs(filesystem.list("/boot")) do
            if filename:match("%.lua$") and filename ~= "boot.lua" then
                table.insert(scripts, "/boot/" .. filename)
            end
        end
        table.sort(scripts)
        return scripts
    end

    --- Run all boot scripts in order.
    --- @return nil
    local function runBootScripts()
        local ok, scripts = pcall(getBootScripts)
        if not ok then
            errorMessage("Failed to get boot scripts: " .. tostring(scripts))
            return
        end
        for _, script in ipairs(scripts) do
            local chunk, load_error = loadfile(script)
            if not chunk then
                errorMessage("Boot Error: " .. script .. ": " .. tostring(load_error))
                while true do computer.pullSignal(1) end
    
            end
            local run, run_error = pcall(chunk)
            if not run then
                errorMessage("Boot Error: " .. script .. ": " .. tostring(run_error))
                while true do computer.pullSignal(1) end
            end
        end
    end

    runBootScripts()
end

--local shell = _G.shell

--local success, err, code = xpcall(shell.run, debug.traceback, shell)
   --if not success then
   --     error("Shell error: " .. tostring(err))
   -- end
dofile("/test/internet_test.lua")