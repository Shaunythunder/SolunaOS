-- /lib/core/internet.lua

local component_manager = _G.component_manager
local sys = require("system")

local internet = {}

    function internet.findInternetCard()
        local internet_cards = component_manager:findComponentsByType("internet")
        if not internet_cards or #internet_cards == 0 then
            return false, "No internet card found"
        end
        local card = internet_cards[1].proxy
        return card, nil
    end

    --- Checks if TCP is enabled on the first available internet card.
    --- @return boolean enabled
    --- @return string|nil error
    function internet.isTcpEnabled()

        local card, err = internet.findInternetCard()
        if not card then
            return false, err
        end

        local function isTcpEnabled(internet_card)
            return internet_card.isTcpEnabled()
        end

        local ok, result = pcall(isTcpEnabled, card)
        if ok then
            return result
        end

        return false, "Error checking TCP status: " .. tostring(result)
    end

    --- Checks if HTTP is enabled on the first available internet card.
    --- @return boolean enabled
    --- @return string|nil error
    function internet.isHttpEnabled()
        local card, err = internet.findInternetCard()
        if not card then
            return false, err
        end

        local function isHttpEnabled(internet_card)
            return internet_card.isHttpEnabled()
        end

        local ok, result = pcall(isHttpEnabled, card)
        if ok then
            return result
        else
            return false, "Error checking HTTP status: " .. tostring(result)
        end
    end

    --- Connects to a given address and port using the first available internet card.
    --- @param address string
    --- @param port number
    --- @return table|false socket
    --- @return string|nil error
    function internet.connect(address, port)
        local card, err = internet.findInternetCard()
        if not card then
            return false, err
        end

        local function connect(internet_card, addr, prt)
            return internet_card.connect(addr, prt)
        end

        local ok, result = pcall(connect, card, address, port)
        if ok then
            return result
        else
            return false, "Error connecting to the internet: " .. tostring(result)
        end
    end

    function internet.request(url, postData, headers)
        local card, err = internet.findInternetCard()
        if not card then
            return nil, err
        end

        local request, reason = card.request(url, postData, headers)
        if not request then
            return nil, reason
        end
        
        local response = setmetatable({}, {
            __call = function()
                while true do
                    local data, err = request.read()
                    if not data then
                        request.close()
                        if err then
                            print("Error reading data:", err)
                            return nil, err
                        else
                            return nil
                        end
                    elseif #data > 0 then 
                        return data
                    end
                    sys.sleep(0)
                end
            end,
            __index = request,
        })
        return response
    end

return internet