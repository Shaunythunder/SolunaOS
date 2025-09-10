-- /lib/core/shell/commands/system/uname.lua

local uname = {}
uname.description = "Displays system information"
uname.usage = "Usage: uname"
uname.flags = {}

    function uname.execute(args, _, _)
        if #args ~= 0 then
            return uname.usage
        end

        -- Globals set in boot.lua
        local os_name = _G.OS_NAME
        local os_version = _G.OS_VERSION
        local os_address = _G.BOOT_ADDRESS

        print("OS Name: " .. os_name)
        print("OS Version: " .. os_version)
        print("OS Address: " .. os_address)
        return ""
    end

return uname