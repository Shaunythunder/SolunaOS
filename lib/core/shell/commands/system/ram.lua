-- /lib/core/shell/commands/system/ram.lua

local os = require("os")
local fs = require("filesystem")

local ram = {}
ram.description = "Displays RAM usage"
ram.usage = "Usage: ram"
ram.flags = {}

    function ram.execute(args, input_data, shell)
        if #args > 0 then
            return ram.usage
        end
        
        local free_ram = fs.normalizeBytes(os.freeMemory())
        local total_ram = fs.normalizeBytes(os.totalMemory())
        local used_ram = fs.normalizeBytes(os.usedMemory())
        local percent_used = (os.usedMemory() / os.totalMemory()) * 100
        print("RAM Usage:")
        print("Total: " .. total_ram .. " bytes")
        print("Free: " .. free_ram .. " bytes")
        print("Used: " .. used_ram .. " bytes")
        print("Percent Used: " .. string.format("%.2f", percent_used) .. "%")
        return ""
    end

return ram