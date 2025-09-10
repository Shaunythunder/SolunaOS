-- /lib/core/shell/commands/system/comp.lua
-- Lists all registered hardware components.

local component_manager = _G.component_manager
local comp = {}
comp.description = "Lists all registered hardware components"
comp.usage = "Usage: comp"
comp.flags = {}

    --- Lists all registered hardware components.
    function comp.execute(args, _, _)
        if #args > 0 then
            return comp.usage
        end
        
        if component_manager then
            local comps = component_manager:listComponents()
            for _, comp in ipairs(comps) do
                print(string.format("Component Type: %s, Address: %s"  , comp.component_type, comp.address))
            end
        else
            print("Error: Component manager not found.")
        end
    end

return comp