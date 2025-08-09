-- init for setting up hardware registries before handing off to main.

do
    local component_invoke = component.invoke
    
    local address, invoke = computer.getBootAddress(), component_invoke
    ---@param file string -- The file to load.
    local function loadfile(file)
        local handle = assert(invoke(address, "open", file))
        local buffer = ""
        repeat
            local data = invoke(address, "read", handle, 4096)
            buffer = buffer .. (data or "")
        until not data
        if #buffer == 0 then
            error("File is empty: " .. file)
        end
        invoke(address, "close", handle)
        return load(buffer, "=" .. file, "bt", _G)
    end

    --- Detect a hardware component(s) and save in register
    ---@param name string -- The name of the hardware component/API type.
    ---@return string  -- A table of addresses (if multiple) for that component.
    local function detectHardware(name)
        local address = component.list(name)()
        if address then
            return address
        else
            return nil
        end
    end

    --[[ Hardware component registry
    A table mapping hardware component names to their addresses
    Entries are optional and can be empty outside of what is needed to run.
    Each entry in the hardware register is a list of all
    detected addresses for that component type. All entries are in table format.
    All entries are in table format whether empty or not.
    ]]
    local hardware_registers = {
        printer3d = detectHardware("printer3d"),
        abstract_bus = detectHardware("abstract_bus"),
        access_point = detectHardware("access_point"),
        chunkloader = detectHardware("chunkloader"),
        computer = detectHardware("computer"),
        data = detectHardware("data"),
        database = detectHardware("database"),
        debug = detectHardware("debug"),
        drone = detectHardware("drone"),
        drive = detectHardware("drive"),
        eeprom = detectHardware("eeprom"),
        experience = detectHardware("experience"),
        filesystem = detectHardware("filesystem"),
        generator = detectHardware("generator"),
        geolyzer = detectHardware("geolyzer"),
        gpu = detectHardware("gpu"),
        hologram = detectHardware("hologram"),
        internet = detectHardware("internet"),
        inventory_controller = detectHardware("inventory_controller"),
        leash = detectHardware("leash"),
        microcontroller = detectHardware("microcontroller"),
        modem = detectHardware("modem"),
        motion_sensor = detectHardware("motion_sensor"),
        navigation = detectHardware("navigation"),
        net_splitter = detectHardware("net_splitter"),
        piston = detectHardware("piston"),
        redstone = detectHardware("redstone"),
        carriage = detectHardware("carriage"),
        robot = detectHardware("robot"),
        screen = detectHardware("screen"),
        sign = detectHardware("sign"),
        tank_controller = detectHardware("tank_controller"),
        tractor_beam = detectHardware("tractor_beam"),
        transposer = detectHardware("transposer"),
        tunnel = detectHardware("tunnel"),
        world_sensor = detectHardware("world_sensor")
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