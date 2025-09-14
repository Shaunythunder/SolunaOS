-- /lib/core/shell/commands/system/diskuse.lua

local component_manager = _G.component_manager
local fs = require("filesystem")

local du = {}
du.description = "Displays disk usage"
du.usage = "Usage: du"
du.flags = {}

function du.execute(args, _, _)
    if #args ~= 0 then
        return du.usage
    end

    local file_systems = component_manager:findComponentsByType("filesystem")

    for _, filesystem in ipairs(file_systems) do
        local address = filesystem.address
        local used_space, total_space = fs.getUsedDiskStorage(address)
        local percent_used = (used_space / total_space) * 100
        used_space = fs.normalizeBytes(used_space)
        total_space = fs.normalizeBytes(total_space)
        print("Filesystem " .. tostring(address) .. ": " .. tostring(used_space) .. " used out of " .. tostring(total_space) .. " (" .. string.format("%.2f", percent_used) .. "% used)")
    end
    return ""
end


return du