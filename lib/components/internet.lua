-- /lib/core/internet.lua

local component_manager = _G.component_manager

local internet = {}

    --- Checks if TCP is enabled on the first available internet card.
    --- @return boolean enabled
    --- @return string|nil error
    function internet.isTcpEnabled()
        local internet_cards = component_manager:findComponentsByType("internet")
        if not internet_cards or #internet_cards == 0 then
            return false, "No internet card found"
        end
        local card = internet_cards[1].proxy

        local function isTcpEnabled(internet_card)
            return internet_card.isTcpEnabled()
        end

        local ok, result = pcall(isTcpEnabled, card)
        if ok then
            return result
        end

        return false, "Error checking TCP status: " .. tostring(result)
    end

return internet