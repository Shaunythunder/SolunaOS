local internet = require("internet")
local sys = require("system")

local enabled, err = internet.isTcpEnabled()
if enabled then
    print("TCP is enabled on the internet card.")
else
    print("TCP is not enabled: " .. err)
end

local enabled, err = internet.isHttpEnabled()
if enabled then
    print("HTTP is enabled on the internet card.")
else
    print("HTTP is not enabled: " .. err)
end

local socket, conn_err = internet.connect("https://github.com/", 80)
if socket then
    print("TCP connection successful!")
else
    print("TCP connection failed:", conn_err)
end

-- Make an HTTP request
local request, req_err = internet.request("https://github.com/")
if request then
    print("HTTP request successful!")
else
    print("HTTP request failed:", req_err)
end

sys.freeze()