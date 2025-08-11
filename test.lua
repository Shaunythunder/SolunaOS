local os = require("os")

os.pullSignal("OS")

while true do
    os.pullSignal(1)
end