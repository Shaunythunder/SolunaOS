-- boot/00_base.lua
-- Summary: Base boot script for SolunaOS, establish file loading, do file and printing.
-- goal is to acheive similar functionality to the original openOS and then branch out from there.

--- Loads files and runs them. Usage is to give the full path to the file, including mnt.
--- Boot version, will redefine once environment is online.
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
