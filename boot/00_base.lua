-- boot/00_base.lua
-- Summary: Base boot script for SolunaOS, establish file loading, do file and printing.
-- goal is to acheive similar functionality to the original openOS and then branch out from there.

--- Opens and runs files on the OS.
--- @param file_path string -- File path to file.
--- @param ... any -- Arguments to pass to the loaded file.
--- @return any -- The return value of the loaded file.
_G.dofile = function(file_path, ...)
    local filesystem = _G.OS_FILESYSTEM
    local filesystem_address = _G.BOOT_ADDRESS
    if not filesystem_address then
        error("No filesystem component found")
    end

    -- Open the file and read its contents
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

    -- Load the file contents as a chunk
    local load_file, load_err = load(buffer, "=" .. file_path, "bt", _G)
    if not load_file then
        error("Failed to load file: " .. load_err)
    end

    -- Call the loaded function with the provided arguments
    local file_ran, result = pcall(load_file, ...)
    if not file_ran then
        error("Failed to execute file: " .. result)
    end
    return result
end

-- Global cache for module loading. Can be dynamically loaded
-- and unloaded with the below functions.
_G.loaded_modules = {}
_G.package = _G.package or {}
package.path = "/lib/?.lua;/lib/core/?.lua;/lib/core/keyboard/?.lua;/usr/lib/?.lua;/?.lua"

--- Loads library or custom API modules.
--- @param module_name string -- The name of the module to load.
--- @return any -- The loaded module or an error message.
_G.require = function(module_name)
    local loaded_modules = _G.loaded_modules
    if loaded_modules[module_name] then
        return loaded_modules[module_name]
    end
    for pattern in package.path:gmatch("[^;]+") do
        local path = pattern:gsub("?", module_name)
        local good_path, result = pcall(_G.dofile, path)
        if good_path then
            loaded_modules[module_name] = result
            return result
        end
    end
    error("Module not found: " .. module_name .. " in package.path")
end

--- Unloads a module by name, removing it from the cache.
--- @param module_name string -- The name of the module to unload.
--- @return boolean -- True if the module was unloaded, false if it was not found.
_G.unrequire = function(module_name)
    local loaded_modules = _G.loaded_modules
    if loaded_modules[module_name] then
        loaded_modules[module_name] = nil
        collectgarbage()
        return true
    else
        return false
    end
end

--- Clears entire module cache.
--- @return nil
_G.wipeRequireCache = function()
    local loaded_modules = _G.loaded_modules
    for entry in pairs(loaded_modules) do
        loaded_modules[entry] = nil
    end
    collectgarbage()
end


--- Temp print function to test rudimentary CLI
--- @param ... any -- Values to print.
--- @return nil
_G.print = function(...)
    local gpu = _G.primary_gpu
    local screen_addr = _G.primary_screen_addr
    local arguments = {...}
    local string = ""

    _G._print_y = _G._print_y or 1

    for i = 1, #arguments do
        string = string .. tostring(arguments[i])
        if i < #arguments then
            string = string .. "\t"
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

dofile("/test.lua")
