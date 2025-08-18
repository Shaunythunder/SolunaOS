local fs = require("filesystem")
local files = fs.list("/")
for _, file in ipairs(files) do
    print(file)
end