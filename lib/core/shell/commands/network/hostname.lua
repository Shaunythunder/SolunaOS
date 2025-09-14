-- /lib/core/shell/commands/networking/hostname.lua

local hostname = {}
hostname.description = "Displays the system's IP address"
hostname.usage = "Usage: hostname [flag]"
hostname.flags = {}

function hostname.execute(args, input_data, shell)
    if #args ~= 0 then
        return hostname.usage
    end

    if 

    if _G.SYSTEM_IP then
        print("System IP Address: " .. _G.SYSTEM_IP)
    else
        print("IP address not set.")
    end
    return ""
end