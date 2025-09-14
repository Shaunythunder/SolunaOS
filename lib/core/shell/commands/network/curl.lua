-- /lib/core/shell/commands/network/curl.lua

local internet = require("internet")

local curl = {}
curl.description = "Sends HTTP requests to a server (GET/POST). Flags require arguments following them. See usage."
curl.usage = "Usage: curl [flags <arg>] <url>"
curl.flags = {
    X = "-X <method> : HTTP method ('GET' or 'POST') Not case sensitive. Default is GET.",
    d = "-d <data> : Data to send in POST request. Data must be string and in quotes if using special characters."
}

local function printUsage()
    print(curl.usage)
    print("Flags:")
    for flag, desc in pairs(curl.flags) do
        print(desc)
    end
end

function curl.execute(args, _, _)
    if #args < 1 then
        printUsage()
        return ""
    end

    local method = "GET"
    local data = nil
    local url = nil

    local i = 1
    while i <= #args do
        local arg = args[i]
        if arg == "-X" and i + 1 <= #args then
            method = args[i + 1]:upper()
            i = i + 1
        elseif arg == "-d" and i + 1 <= #args then
            data = args[i + 1]
            i = i + 1
        elseif not url then
            url = arg
        end
        i = i + 1
    end

    if not url then
        printUsage()
        return ""
    end

    if method == "POST" and not data then
        return "Error: POST method requires data (-d <DATA>)"
    end

    local handle, err
    if method == "POST" then
        handle, err = internet.request(url, data)
    else
        handle, err = internet.request(url)
    end

    if not handle then
        return "Error: Unable to connect to URL: " .. tostring(err)
    end

    local response = {}
    for chunk in handle do
        table.insert(response, chunk)
    end
    handle:close()

    return table.concat(response)

end

return curl