-- /lib/core/shell/commands/system/diskfree.lua

local component_manager = _G.component_manager
local fs = require("filesystem")

local df = {}
df.description = "Displays free disk space"
df.usage = "Usage: df"
df.flags = {}

function df.execute(args, _, _)
    if #args ~= 0 then
        return df.usage
    end

    local file_systems = component_manager:findComponentsByType("filesystem")

    for _, filesystem in ipairs(file_systems) do
        local address = filesystem.address
        local free_space, total_space = fs.getFreeDiskStorage(address)
        local percent_free = (free_space / total_space) * 100
        free_space = fs.normalizeBytes(free_space)
        total_space = fs.normalizeBytes(total_space)
        print("Filesystem " .. tostring(address) .. ": " .. tostring(free_space) .. " free out of " .. tostring(total_space) .. " (" .. string.format("%.2f", percent_free) .. "% free)")
    end
    return ""
end

return df