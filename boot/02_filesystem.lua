-- /boot/02_filesystem.lua
-- Initializes the filesystem and mounts any available disks

local component = _G.component_manager
local fs = require("filesystem")
local os = require("os")

_G.mounted_filesystems = {}
local attached_filesystems = component:findComponentsByType("filesystem")

for _, filesystem in ipairs(attached_filesystems) do
    local address = filesystem.address
    if address ~= _G.BOOT_ADDRESS then
        local ok, err = pcall(fs.mount, address)
        if not ok then
            print("Error mounting filesystem at " .. address .. ": " .. err)
        end
        os.sleep(0)
    end
end

if not fs.exists("/home") then
    fs.makeDirectory("/home")
end

print("=== MOUNTED FILESYSTEMS ===")
for mount_point, mount_info in pairs(_G.mounted_filesystems) do
    print("Mount point: '" .. mount_point .. "'")
    print("Address:", mount_info.address)
    print("Structure exists:", mount_info.structure ~= nil)
    print("---")
end

local Shell = require("shell")
local shell = Shell.new()
shell:run()