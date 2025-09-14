-- boot/00_base.lua

--- Temp print function to test rudimentary CLI
--- @param ... any -- Values to print.
--- @return nil
_G.bootPrint = function(...)
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
--- @param file_path string
--- @param ... any
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

local core_path = "/lib/core/?.lua"
local shell_path = "/lib/core/shell/?.lua"
local gui_core_path = "/lib/desktop/core/?.lua"
local gui_window_path = "/lib/desktop/core/window/?.lua"
local gui_taskbar_path = "/lib/desktop/core/taskbar/?.lua"
local gui_icons_path = "/lib/desktop/core/icons/?.lua"
local component_path = "/lib/component_drivers/?.lua"
local term_apps_path = "/lib/terminal_apps/?.lua"
local gui_widgets_path = "/lib/desktop/widgets/?.lua"
local apps_path = "/apps/?.lua"
local utilities_path = "/utilities/?.lua"
local assets_path = "/assets/?.lua"
local lib_path = "/lib/?.lua"
local cmd_env_path = "/lib/core/shell/commands/environment/?.lua"
local cmd_fs_path = "/lib/core/shell/commands/filesystem/?.lua"
local cmd_misc_path = "/lib/core/shell/commands/misc/?.lua"
local cmd_nav_path = "/lib/core/shell/commands/navigation/?.lua"
local cmd_net_path = "/lib/core/shell/commands/network/?.lua"
local cmd_sh_path = "/lib/core/shell/commands/sh/?.lua"
local cmd_sys_path = "/lib/core/shell/commands/system/?.lua"
local cmd_text_path = "/lib/core/shell/commands/text/?.lua"
local asset_tables_path = "/assets/asset_tables/?.lua"
local custom_path = "?.lua"

package.path =  core_path .. ";" ..
                shell_path .. ";" ..
                gui_core_path .. ";" ..
                gui_window_path .. ";" ..
                gui_taskbar_path .. ";" ..
                gui_icons_path .. ";" ..
                component_path .. ";" ..
                term_apps_path .. ";" ..
                gui_widgets_path .. ";" ..
                apps_path .. ";" ..
                utilities_path .. ";" ..
                assets_path .. ";" ..
                cmd_env_path .. ";" ..
                cmd_fs_path .. ";" ..
                cmd_misc_path .. ";" ..
                cmd_nav_path .. ";" ..
                cmd_net_path .. ";" ..
                cmd_sh_path .. ";" ..
                cmd_sys_path .. ";" ..
                cmd_text_path .. ";" ..
                lib_path .. ";" ..
                asset_tables_path .. ";" ..
                custom_path

--- Loads library or custom API modules.
--- @param mod_name string
--- @return any
_G.require = function(mod_name)
    local loaded_mods = _G.loaded_modules
    if loaded_mods[mod_name] then
        return loaded_mods[mod_name]
    end
    local traceback
    for pattern in package.path:gmatch("[^;]+") do
        local path = pattern:gsub("?", mod_name)
        local good_path, result = xpcall(_G.dofile, debug.traceback, path)
        if good_path and result ~= nil then
            loaded_mods[mod_name] = result
            return result
        elseif not good_path and not result:match("Failed to open file:") then
            traceback = result
        end
    end
    error("Error loading module " .. mod_name .. ":\n" .. tostring(traceback))
end

--- Removes module from global cache
--- @param mod_name string
--- @return boolean result
_G.unrequire = function(mod_name)
    local loaded_mods = _G.loaded_modules
    if loaded_mods[mod_name] then
        loaded_mods[mod_name] = nil
        collectgarbage()
        return true
    else
        return false
    end
end

--- Clears entire module cache.
_G.wipeRequireCache = function()
    local loaded_mods = _G.loaded_modules
    for entry in pairs(loaded_mods) do
        loaded_mods[entry] = nil
    end
    collectgarbage()
end
