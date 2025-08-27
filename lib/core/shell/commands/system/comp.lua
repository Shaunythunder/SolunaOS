-- /lib/core/shell/commands/system/comp.lua
-- Lists all registered hardware components.

local component_manager = _G.component_manager
local comp = {}

    --- Lists all registered hardware components.
    function comp.execute(args, input_data, shell)
        if #args > 0 then
            return "Usage: comp"
        end
        
        if component_manager then
            local components = component_manager:listComponents()
            for _, component in ipairs(components) do
                print(string.format("Component Type: %s, Address: %s"  , component.component_type, component.address))
            end
        else
            print("Error: Component manager not found.")
        end
    end

return comp