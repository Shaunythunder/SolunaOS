-- lib/core/shell/commands/system/lua.lua

local fs = require("filesystem")

local lua = {}
lua.description = "Executes a Lua script"
lua.usage = "Usage: lua <script.lua>"
lua.flags = {}

    function lua.execute(args, input_data, shell)
        if #args == 0 then
            return lua.usage
        end
        
        local script = args[1]
        
        if not fs.exists(script) then
            return "Error: Script does not exist: " .. script
        end
        
        dofile(script)
        return ""
    end

return lua