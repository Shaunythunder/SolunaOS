-- /lib/core/shell/commands/networking/wget.lua

local fs = require("filesystem")
local internet = require("internet")

local wget = {}
wget.description = "Downloads a file from a URL and saves it"
wget.usage = "Usage: wget <url> <output_file>"
wget.flags = {}

    function wget.execute(args, input_data, shell)

        if #args ~= 2 then
            return wget.usage
        end

        local url = args[1]
        local output_file = args[2]
        local handle, err = internet.request(url)
        if not handle then
            return "Error: Unable to connect to URL: " .. tostring(err)
        end

        local file, file_err = fs.open(output_file, "w")
        if not file then
            return "Error: Unable to open file for writing: " .. tostring(file_err)
        end

        for chunk in handle do
            fs.write(file, chunk)
        end

        fs.close(file)
        handle:close()
        return "Downloaded " .. url .. " to " .. output_file
    end

return wget