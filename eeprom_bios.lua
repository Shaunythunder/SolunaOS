-- For use in EEPROM
local component = component or require("component")
local filesystem = component.list("filesystem")()
local gpu = component.list("gpu") and component.proxy(component.list("gpu")())
local screen = component.list("screen") and component.proxy(component.list("screen")())
 
local boot_address
computer.setBootAddress = function(address)
    boot_address = address
end
computer.getBootAddress = function() 
    return boot_address
end


local function gpuMsg(msg)
    if gpu and screen then
        gpu.bind(screen.address)
        gpu.set(1, 1, msg)
    end
end

if filesystem then 
    boot_address = filesystem
    local handle = component.invoke(filesystem, "open", "/init.lua")
    if handle then
        local data = ""
        repeat
            local chunk = component.invoke(filesystem, "read", handle, math.huge)
            if chunk then
                data = data .. chunk
            end
        until not chunk
        component.invoke(filesystem, "close", handle)
        local func, error = load(data, "=init")
        if func then 
            func()
        else
            gpuMsg("OS Error: " .. error)
        end
    else
        gpuMsg("OS Error: Unable to open /init.lua")
    end
else
    gpuMsg("OS Error: No filesystem component found")
end-- For use in EEPROM
local component = component or require("component")
local filesystem = component.list("filesystem")()
local gpu = component.list("gpu") and component.proxy(component.list("gpu")())
local screen = component.list("screen") and component.proxy(component.list("screen")())
 
local boot_address
computer.setBootAddress = function(address)
    boot_address = address
end
computer.getBootAddress = function() 
    return boot_address
end


local function gpuMsg(msg)
    if gpu and screen then
        gpu.bind(screen.address)
        gpu.set(1, 1, msg)
    end
end

if filesystem then 
    boot_address = filesystem
    local handle = component.invoke(filesystem, "open", "/init.lua")
    if handle then
        local data = ""
        repeat
            local chunk = component.invoke(filesystem, "read", handle, math.huge)
            if chunk then
                data = data .. chunk
            end
        until not chunk
        component.invoke(filesystem, "close", handle)
        local func, error = load(data, "=init")
        if func then 
            func()
        else
            gpuMsg("OS Error: " .. error)
        end
    else
        gpuMsg("OS Error: Unable to open /init.lua")
    end
else
    gpuMsg("OS Error: No filesystem component found")
end