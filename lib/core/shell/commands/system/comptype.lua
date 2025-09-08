-- /lib/core/shell/commands/system/comptype.lua

local component_manager = _G.component_manager

local comptype = {}
comptype.description = "Lists all registered hardware components of specified type"
comptype.usage = "Usage: comptype <component_type>"
comptype.flags = {}

    --- Lists all registered hardware components of specified type.
    function comptype.execute(args, input_data, shell)
        if #args ~= 1 then
            return comptype.usage
        end

        local component_type = args[1]
        if component_manager then
            local components = component_manager:findComponentsByType(component_type)
            for _, component in ipairs(components) do
                print(string.format("Component Type: %s, Address: %s"  , component.component_type, component.address))
            end
        else
            print("Error: Component manager not found.")
        end
    end

return comptype