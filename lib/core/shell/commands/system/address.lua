-- /lib/core/shell/commands/system/address.lua

local address = {}
address.description = "Displays the system's unique address"
address.usage = "Usage: address"
address.flags = {}

function address.execute(args, _, _)
    if #args ~= 0 then
        return address.usage
    end

    local addr = computer.getBootAddress()
    if addr then
        print("System Address: " .. addr)
    else
        print("Unable to retrieve system address.")
    end
    return ""
end

return address