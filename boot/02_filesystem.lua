-- /boot/02_filesystem.lua
-- Initializes the filesystem and mounts any available disks

local component = _G.component_manager
local scroll_buffer = _G.scroll_buffer
local fs = require("filesystem")
local sys = require("system")

_G.mounted_filesystems = {}
local attached_filesystems = component:findComponentsByType("filesystem")

for _, filesystem in ipairs(attached_filesystems) do
    local address = filesystem.address
    if address ~= _G.BOOT_ADDRESS then
        local ok, err = pcall(fs.mount, address)
        if not ok then
            print("Error mounting filesystem at " .. address .. ": " .. err)
        end
        sys.sleep(0)
    end
end

if not fs.exists("/home") then
    fs.makeDirectory("/home")
end

if not fs.exists("/tmp") then
    fs.makeDirectory("/tmp")
else
    fs.removeRecursive("/tmp")
    fs.makeDirectory("/tmp")
end

scroll_buffer:enableLogging()
scroll_buffer:setLogFilePath("/tmp/scroll_buffer.log")

local Shell = require("shell")
local shell = Shell.new()
_G.shell = shell

