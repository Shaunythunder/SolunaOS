-- boot/00_base.lua

--- Temp print function to test rudimentary CLI
--- @param ... any -- Values to print.
--- @return nil
_G.print = function(...)
    local gpu = _G.primary_gpu
    local screen_addr = _G.primary_screen_addr
    local args = {...}
    local string = ""

    _G._print_y = _G._print_y or 1

    for i = 1, #args do
        string = string .. tostring(args[i])
        if i < #args then
            string = string .. " "
        end
    end

    gpu.bind(screen_addr)
    local width, height = gpu.getResolution()
    if _G._print_y == 1 then
        gpu.fill(1, 1, width, height, " ")
    end
    gpu.set(1, _G._print_y, string)
    _G._print_y = _G._print_y + 1
    if _G._print_y > height then
        _G._print_y = 1
        gpu.fill(1, 1, width, height, " ")
    end
end

--- Opens and runs files on the OS.
--- @param file_path string -- File path to file.
--- @param ... any -- Arguments (optional)
--- @return any
_G.dofile = function(file_path, ...)
    local filesystem = _G.OS_FILESYSTEM
    local filesystem_address = _G.BOOT_ADDRESS
    if not filesystem_address then
        error("No filesystem component found")
    end

    local handle, fs_err = filesystem.open(file_path, "r")
    if not handle then
        error("Failed to open file: " .. fs_err)
    end

    local buffer = ""
    repeat
        local data = filesystem.read(handle, 4096)
        buffer = buffer .. (data or "")
    until not data
    if #buffer == 0 then
        error("File is empty: " .. file_path)
    end
    filesystem.close(handle)

    local load_file, load_err = load(buffer, "=" .. file_path, "bt", _G)
    if not load_file then
        error("Failed to load file: " .. load_err)
    end

    local file_ran, result = xpcall(load_file, debug.traceback, ...)
    if not file_ran then
        error("Failed to execute file: " .. file_path .. " " .. result)
    end
    return result
end


_G.loaded_modules = {}
_G.package = _G.package or {}

-- Package paths for module loading
-- These paths allow require("<module_name>") instead of the full path
local lib_path = "/lib/?.lua"
local core_path = "/lib/core/?.lua"
local event_path = "/lib/core/event/?.lua"
local custom_path = "?.lua"

package.path = lib_path .. ";" ..
               core_path .. ";" ..
               event_path .. ";" ..
               custom_path

               
--- Loads library or custom API modules.
--- @param mod_name string
--- @return any
_G.require = function(mod_name)
    local loaded_modules = _G.loaded_modules
    if loaded_modules[mod_name] then
        return loaded_modules[mod_name]
    end
   for pattern in package.path:gmatch("[^;]+") do
    local path = pattern:gsub("?", mod_name)
    local good_path, result = xpcall(_G.dofile, debug.traceback, path)
    -- Only treat as success if the file pcalled and returned non-nil
    if good_path then
        local module_result = result
        loaded_modules[mod_name] = result
        return result
    end
end
error("Error loading module " .. mod_name .. ": " .. tostring(result))
end

--- Removes module from global cache
--- @param mod_name string
--- @return boolean result
_G.unrequire = function(mod_name)
    local loaded_modules = _G.loaded_modules
    if loaded_modules[mod_name] then
        loaded_modules[mod_name] = nil
        collectgarbage()
        return true
    else
        return false
    end
end

--- Clears entire module cache.
_G.wipeRequireCache = function()
    local loaded_modules = _G.loaded_modules
    for entry in pairs(loaded_modules) do
        loaded_modules[entry] = nil
    end
    collectgarbage()
end
