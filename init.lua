-- init for setting up hardware registries before handing off to main.

do
    local component_invoke = component.invoke
    
    local addr, invoke = computer.getBootAddress(), component_invoke
    ---@param file string -- The file to load.
    local function loadfile(file)
        local handle = assert(invoke(addr, "open", file))
        local buffer = ""
        repeat
            local data = invoke(addr, "read", handle, 4096)
            buffer = buffer .. (data or "")
        until not data
        if #buffer == 0 then
            error("File is empty: " .. file)
        end
        invoke(addr, "close", handle)
        return load(buffer, "=" .. file, "bt", _G)
    end

    --- Detect a hardware component(s) and save in register
    ---@param name string -- The name of the hardware component/API type.
    ---@return table|nil  -- The address and proxy for the component, or nil if not found.
    local function detectHardware(name)
        local devices = {}
        for address in component.list(name, true) do
            local proxy = component.proxy(address)
            table.insert(devices, {
                address = address,  -- string
                proxy   = proxy     -- table (methods, .address, .type)
            })
        end
        if #devices > 0 then
            return devices
        end
    end

  --[[
    Hardware component registry
    A table mapping hardware component names to their first detected proxy (or nil if not found).
    Each entry is an array of {address, proxy} tables for all detected components of that type, or nil if none found
    ]]
    local hardware_registers = {
    printer3d            = detectHardware("printer3d"),
    abstract_bus         = detectHardware("abstract_bus"),
    access_point         = detectHardware("access_point"),
    chunkloader          = detectHardware("chunkloader"),
    computer             = detectHardware("computer"),
    data                 = detectHardware("data"),
    database             = detectHardware("database"),
    debug                = detectHardware("debug"),
    drone                = detectHardware("drone"),
    drive                = detectHardware("drive"),
    eeprom               = detectHardware("eeprom"),
    experience           = detectHardware("experience"),
    filesystem           = detectHardware("filesystem"),
    generator            = detectHardware("generator"),
    geolyzer             = detectHardware("geolyzer"),
    gpu                  = detectHardware("gpu"),
    hologram             = detectHardware("hologram"),
    internet             = detectHardware("internet"),
    inventory_controller = detectHardware("inventory_controller"),
    leash                = detectHardware("leash"),
    microcontroller      = detectHardware("microcontroller"),
    modem                = detectHardware("modem"),
    motion_sensor        = detectHardware("motion_sensor"),
    navigation           = detectHardware("navigation"),
    net_splitter         = detectHardware("net_splitter"),
    piston               = detectHardware("piston"),
    redstone             = detectHardware("redstone"),
    carriage             = detectHardware("carriage"),
    robot                = detectHardware("robot"),
    screen               = detectHardware("screen"),
    sign                 = detectHardware("sign"),
    tank_controller      = detectHardware("tank_controller"),
    tractor_beam         = detectHardware("tractor_beam"),
    transposer           = detectHardware("transposer"),
    tunnel               = detectHardware("tunnel"),
    world_sensor         = detectHardware("world_sensor")
    }

-- INSERT SPLASH SCREEN LOGIC 
-- INSERT SPLASH SCREEN LOGIC 
-- INSERT SPLASH SCREEN LOGIC 
-- INSERT SPLASH SCREEN LOGIC 
-- INSERT SPLASH SCREEN LOGIC 

    local main, error = loadfile("/main.lua")
    if main then
        local ok, error = pcall(main, hardware_registers)
        if not ok then
            error("Failed to run main.lua: " .. tostring(error))
        end
    else
        error("Failed to load main.lua: " .. tostring(error))
    end
end