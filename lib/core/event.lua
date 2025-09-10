-- lib/core/event.lua

local fs = require("filesystem")
local cursor = _G.cursor

local event = {}
event.__index = event

    event.new = function()
        local self = setmetatable({}, { __index = event })
        self.event_handlers = {}
        self:initHandlers()
        return self
    end

    -- Returns the handler function for a given event type
    --- @param event_type string
    --- @return any|nil handler_function
    function event:getHandler(event_type)
        return self.event_handlers[event_type]
    end

    -- Validates if an event type is recognized
    --- @param event_type string
    --- @return string|nil valid_event_type
    function event:getEventType(event_type)
        return self.event_handlers[event_type] and event_type or nil
    end

    function event:reset()
        self.event_handlers = {}
        self:initHandlers()
    end

    --- Listens for an event with an optional timeout.
    --- @param timeout number|nil
    --- @return any function_result
    function event:listen(timeout)
        local event_args = {computer.pullSignal(timeout)}
        if not event_args[1] then
            return
        end
        local event_type = event_args[1]
        return self:trigger(event_type, table.unpack(event_args, 2))
    end

    --- Triggers an event based on signal
    --- @param ... any
    --- @return any function_result passes to event:listen()
    function event:trigger(event_type, ...)
        cursor:show()
        local handler_entry = self.event_handlers[event_type]
        if handler_entry and handler_entry.handler then
            return handler_entry.handler(event_type, ...)
        end
    end

    --- Handles key down events
    function event:keyDown(_, _, _, key_code)
        local keyboard = _G.keyboard
        return keyboard:triggerKeyDown(key_code)
    end

    --- Handles key up events
    function event:keyUp(_, _, _, key_code)
        local keyboard = _G.keyboard
        return keyboard:triggerKeyUp(key_code)
    end

    function event:clipboard(event_type, text)
        return event_type, text
    end
    
    function event:touch(event_type, screen_addr, x_pos, y_pos, mouse_button, player_name)
        return event_type, screen_addr, x_pos, y_pos, mouse_button, player_name
    end

    function event:drag(event_type, screen_addr, x_pos, y_pos, mouse_button, player_name)
        return event_type, screen_addr, x_pos, y_pos, mouse_button, player_name
    end

    function event:drop(event_type, screen_addr, x_pos, y_pos, mouse_button, player_name)
        return event_type, screen_addr, x_pos, y_pos, mouse_button, player_name
    end

    function event:scroll(event_type, screen_addr, x_pos, y_pos, direction, player_name)
        return event_type, screen_addr, x_pos, y_pos, direction, player_name
    end

    function event:walk(event_type, screen_addr, x_pos, y_pos, player_name)
        return event_type, screen_addr, x_pos, y_pos, player_name
    end

    --- Hotplugging. Takes address makes proxy and then adds to registry.
    function event:componentAdded(_, address, component_type)
        local component_manager = _G.component_manager
        if component_manager then
            local proxy = component.proxy(address)
            if proxy then
                component_manager:addComponent(component_type, address, proxy)
                if component_type == "filesystem" and address ~= _G.BOOT_ADDRESS then
                    local ok, err = pcall(fs.mount, address)
                    if not ok then
                        print("Error auto-mounting filesystem " .. address .. ": " .. err)
                    end
                end
                return true
            end
        end
        return false
    end

    --- Hotplugging. Removes from registry.
    function event:componentRemoved(_, address, component_type)
        local component_manager = _G.component_manager
        if component_manager then
            component_manager:removeComponent(component_type, address)
            if component_type == "filesystem" then
                local mnt_point = fs.concat("/mnt/", string.sub(address, 1, 3))
                fs.unmount(mnt_point)
            end
            return true
        end
        return false
    end

    function event:componentAvailable(event_type, address, component_type)
        return event_type, address, component_type
    end

    function event:componentUnavailable(event_type, address, component_type)
        return event_type, address, component_type
    end

    function event:interrupted(event_type, uptime)
        return event_type, uptime
    end

    function event:modemMessage(event_type, receiver_addr, sender_addr, port, distance, ...)
        return event_type, receiver_addr, sender_addr, port, distance, ...
    end

    -- Handles screen resize events and resets buffers
    function event:screenResized(event_type, screen_addr, new_width, new_height)
        if screen_addr == _G.primary_screen_addr then
            local gpu = _G.primary_gpu
            _G.width = new_width
            _G.height = new_height
            gpu.freeAllBuffers()
            _G.vram_buffer = nil
            _G.vram_buffer = gpu.allocateBuffer(new_width, new_height)
            return
        end
        return event_type, screen_addr, new_width, new_height
    end

    function event:termAvailable()
        _G.display_available = true
    end

    function event:termUnavailable()
        _G.display_available = false
    end

    function event:redstoneChanged(event_type, address, side, old_value, new_value, color)
        return event_type, address, side, old_value, new_value, color
    end

    function event:motion(event_type, address, relative_x, relative_y, relative_z, entity_name)
        return event_type, address, relative_x, relative_y, relative_z, entity_name
    end

    function event:inventoryChanged(event_type, slot)
        return event_type, slot
    end

    function event:busMessage(event_type, protocol_id, sender_addr, target_addr, data, metadata)
        return event_type, protocol_id, sender_addr, target_addr, data, metadata
    end

    function event:carriageMoved(event_type, result, error, x_pos, y_pos, z_pos)
        return event_type, result, error, x_pos, y_pos, z_pos
    end

    function event:initHandlers()
        self.event_handlers = {
            ["key_down"] = {handler = function(...) return self:keyDown(...) end},
            ["key_up"] = {handler = function(...) return self:keyUp(...) end},
            ["clipboard"] = {handler = function(...) return self:clipboard(...) end},
            ["touch"] = {handler = function(...) return self:touch(...) end},
            ["drag"] = {handler = function(...) return self:drag(...) end},
            ["drop"] = {handler = function(...) return self:drop(...) end},
            ["scroll"] = {handler = function(...) return self:scroll(...) end},
            ["walk"] = {handler = function(...) return self:walk(...) end},
            ["component_added"] = {handler = function(...) return self:componentAdded(...) end},
            ["component_removed"] = {handler = function(...) return self:componentRemoved(...) end},
            ["component_available"] = {handler = function(...) return self:componentAvailable(...) end},
            ["component_unavailable"] = {handler = function(...) return self:componentUnavailable(...) end},
            ["interrupted"] = {handler = function(...) return self:interrupted(...) end},
            ["modem_message"] = {handler = function(...) return self:modemMessage(...) end},
            ["screen_resized"] = {handler = function(...) return self:screenResized(...) end},
            ["term_available"] = {handler = function() return self:termAvailable() end},
            ["term_unavailable"] = {handler = function() return self:termUnavailable() end},
            ["redstone_changed"] = {handler = function(...) return self:redstoneChanged(...) end},
            ["motion"] = {handler = function(...) return self:motion(...) end},
            ["inventory_changed"] = {handler = function(...) return self:inventoryChanged(...) end},
            ["bus_message"] = {handler = function(...) return self:busMessage(...) end},
            ["carriage_moved"] = {handler = function(...) return self:carriageMoved(...) end}
        }
    end

return event