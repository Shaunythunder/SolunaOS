local internet = require("internet")
local os = require("os")

local enabled, err = internet.isTcpEnabled()
if enabled then
    print("TCP is enabled on the internet card.")
else
    print("TCP is not enabled: " .. err)
end

os.freeze()