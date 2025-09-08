-- /lib/core/shell/commands/system/address.lua

local address = {}
address.description = "Displays the system's unique address"
address.usage = "Usage: address"
address.flags = {}

    function address.execute(args, input_data, shell)
        if #args ~= 0 then
            return address.usage
        end

        local address = computer.getBootAddress()
        if address then
            print("System Address: " .. address)
        else
            print("Unable to retrieve system address.")
        end
        return ""
    end

return address