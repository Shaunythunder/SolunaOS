-- /lib/core/component.lua
-- Container for hardware component proxies and addresses.

local comp_manager = {}
comp_manager.__index = comp_manager

function comp_manager.new()
    local self = setmetatable({}, comp_manager)
    self.comp_registry = _G.hardware_registers -- see init.lua and boot.lua
    return self
end

function comp_manager:clearComponents()
    self.comp_registry = {}
end

--- Detect a hardware component(s) and save in register
---@param comp_type string
---@return table|nil component -- address and proxy
function comp_manager:detectHardware(comp_type)
    local devices = {}
    for address in component.list(comp_type, true) do
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
--- @param comp_type string
--- @param address string
--- @param proxy table
--- @return boolean success
--- @return string|nil error
function comp_manager:addComponent(comp_type, address, proxy)
    if comp_type == nil or address == nil or proxy == nil then
        return false, "Error: nil parameter"
    end
    self.comp_registry[comp_type] = self.comp_registry[comp_type] or {}
    table.insert(self.comp_registry[comp_type], {
        address = address,
        proxy = proxy
    })
    return true
end

--- Removes a component from the registry.
--- @param comp_type string
--- @param address string
--- @return boolean success
--- @return string|nil error
function comp_manager:removeComponent(comp_type, address)
    if comp_type == nil or address == nil then
        return false, "Error: nil parameter"
    end
    if self.comp_registry[comp_type] then
        for i, comp_data in ipairs(self.comp_registry[comp_type]) do
            if comp_data.address == address then
                table.remove(self.comp_registry[comp_type], i)
                return true
            end
        end
    end
    return false, "Error: component not found"
end

--- Lists all registered components with their types and addresses.
--- @return table component_list
function comp_manager:listComponents()
    local comps = {}
    for comp_type, comp_metadata in pairs(self.comp_registry) do
        for _, component_data in ipairs(comp_metadata) do
            table.insert(comps, {
                component_type = comp_type,
                address = component_data.address,
            })
        end
    end
    return comps
end

--- Finds all registered hardware components of specified type.
--- @param comp_type string
--- @return table|nil component_list
--- @return string|nil error
function comp_manager:findComponentsByType(comp_type)
    if comp_type == nil then
        return {}, "Error: nil parameter"
    end
    local found_comps = {}
    for _, comp_data in ipairs(self.comp_registry[comp_type] or {}) do
        table.insert(found_comps, {
            component_type = comp_type,
            address = comp_data.address,
            proxy = comp_data.proxy
        })
    end
    return found_comps
end

return comp_manager