local function runTest()
    local fs = require("filesystem")
    
    local file = fs.open("/install_manifest.lua", "r")
    _G.bootPrint("file_object type: " .. type(file))
    _G.bootPrint("hardware_component type: " .. type(file.hardware_component))
    _G.bootPrint("hardware_component: " .. tostring(file.hardware_component))
    _G.bootPrint("handle: " .. tostring(file.handle))
    
    local data = file.hardware_component:read(file.handle, math.huge)
    _G.bootPrint("Data returned: " .. tostring(data))
    _G.bootPrint("Data type: " .. type(data))
    
    fs.close(file)
end

runTest()

while true do
    computer.pullSignal()
end