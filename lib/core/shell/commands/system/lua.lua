-- lib/core/shell/commands/system/lua.lua

local fs = require("filesystem")
local lua = {}

function lua.execute(args, input_data, shell)
    if #args == 0 then
        return "Usage: lua <script.lua>"
    end
    
    local script = args[1]
    
    if not fs.exists(script) then
        return "Error: Script does not exist: " .. script
    end
    
    dofile(script)
    return ""
end

return lua