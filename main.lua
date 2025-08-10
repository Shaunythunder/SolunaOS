-- main.lua
-- Runs the main loop for SolunaOS
-- SolunaOS is a manager based operating system which uses a main loop.

-- Pass hardware_registers and file loading to main from init.lua
local hardware_registers, loadfile = ...

--- Loads manager into main via protected call. Sends an error on failure.
--- @param manager_path string - The path to the manager file.
--- @return table - The loaded manager module.
local function loadManager(manager_path)
    local ok, manager_load = pcall(loadfile, manager_path)
    if not ok then
        error("Failed to load manager: " .. manager_path)
    end
    local manager = manager_load()
    return manager
end

-- Load all necessary managers
local cli_manager = loadManager("lib/cli/cli_manager.lua")
local terminal_manager = loadManager("lib/terminal/terminal_manager.lua")
local driver_manager = loadManager("lib/drivers/driver_manager.lua")
local garbage_manager = loadManager("lib/garbage/garbage_manager.lua")
local gui_manager = loadManager("lib/gui/gui_manager.lua")
local networking_manager = loadManager("lib/networking/networking_manager.lua")

-- Main OS loop
local running = true
while running do
    local event = {computer.pullSignal()}
    running = cli_manager:handleEvent(event)
end

