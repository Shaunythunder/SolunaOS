-- /lib/core/shell/commands/network/intping.lua

local internet = require("internet")

local intping = {}
intping.description = "Pings a real-world server using HTTP GET."
intping.usage = "Usage: intping <url>"
intping.flags = {}

function intping.execute(args, input_data, shell)
    if #args ~= 1 then
        return intping.usage
    end

    local url = args[1]
    local start = os.clock()    
    local elapsed = (os.clock() - start) * 1000 -- ms

    local handle, err = internet.request(url)
    if not handle then
        return "Ping failed: " .. tostring(err)
    end

    handle:close()
    return string.format("Ping to %s: success (%.2f ms)", url, elapsed)
end

return intping