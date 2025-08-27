-- /lib/core/component.lua
-- Container for hardware component proxies and addresses.

local component_manager = {}
component_manager.__index = component_manager

    function component_manager.new()
        local self = setmetatable({}, component_manager)
        self.component_registry = _G.hardware_registers -- see init.lua and boot.lua
        return self
    end

    function component_manager:clearComponents()
        self.component_registry = {}
    end

    --- Detect a hardware component(s) and save in register
    ---@param component_type string -- The name of the hardware component/API type.
    ---@return table|nil component -- The address and proxy for the component, or nil if not found.
    function component_manager:detectHardware(component_type)
        local devices = {}
        for address in component.list(component_type, true) do
            local proxy = component.proxy(address)
            table.insert(devices, {
                address = address,
                proxy   = proxy
            })
        end
        if #devices > 0 then
            return devices
        end
    end

    --- Adds a component to the registry.
    --- @param component_type string
    --- @param address string
    --- @param proxy table
    --- @return boolean success
    --- @return string|nil error
    function component_manager:addComponent(component_type, address, proxy)
        if component_type == nil or address == nil or proxy == nil then
            return false, "Error: nil parameter"
        end
        self.component_registry[component_type] = self.component_registry[component_type] or {}
        table.insert(self.component_registry[component_type], {
            address = address,
            proxy = proxy
        })
        return true
    end
    
    --- Removes a component from the registry.
    --- @param component_type string
    --- @param address string
    --- @return boolean success
    --- @return string|nil error
    function component_manager:removeComponent(component_type, address)
        if component_type == nil or address == nil then
            return false, "Error: nil parameter"
        end
        if self.component_registry[component_type] then
            for i, component_data in ipairs(self.component_registry[component_type]) do
                if component_data.address == address then
                    table.remove(self.component_registry[component_type], i)
                    return true
                end
            end
        end
        return false, "Error: component not found"
    end

    --- Lists all registered components with their types and addresses.
    --- @return table component_list
    function component_manager:listComponents()
        local components = {}
        for component_type, component_metadata in pairs(self.component_registry) do
            for _, component_data in ipairs(component_metadata) do
                table.insert(components, {
                    component_type = component_type,
                    address = component_data.address,
                })
            end
        end
        return components
    end

    --- Finds all registered hardware components of specified type.
    --- @param component_type string
    --- @return table|nil component_list
    --- @return string|nil error
    function component_manager:findComponentsByType(component_type)
        if component_type == nil then
            return {}, "Error: nil parameter"
        end
        local found_components = {}
        for _, component_data in ipairs(self.component_registry[component_type] or {}) do
            table.insert(found_components, {
                component_type = component_type,
                address = component_data.address,
            })
        end
        return found_components
    end

return component_manager