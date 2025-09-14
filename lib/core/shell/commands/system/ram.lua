-- /lib/core/shell/commands/system/ram.lua

local sys = require("system")
local fs = require("filesystem")

local ram = {}
ram.description = "Displays RAM usage"
ram.usage = "Usage: ram"
ram.flags = {}

function ram.execute(args, _, _)
    if #args > 0 then
        return ram.usage
    end

    local free_ram = fs.normalizeBytes(sys.freeMemory())
    local total_ram = fs.normalizeBytes(sys.totalMemory())
    local used_ram = fs.normalizeBytes(sys.usedMemory())
    local percent_used = (sys.usedMemory() / sys.totalMemory()) * 100
    print("RAM Usage:")
    print("Total: " .. total_ram .. " bytes")
    print("Free: " .. free_ram .. " bytes")
    print("Used: " .. used_ram .. " bytes")
    print("Percent Used: " .. string.format("%.2f", percent_used) .. "%")
    return free_ram, total_ram, used_ram, percent_used
end

return ram