-- /lib/core/shell/commands/system/date.lua

local osdate = {}
osdate.description = "Displays the current date and time"
osdate.usage = "Usage: osdate"
osdate.flags = {}

    function osdate.execute(args, _, _)
        if #args ~= 0 then
            return osdate.usage
        end

        local current_time = os.date("*t")
        print(string.format("Current OS Date and Time: %04d-%02d-%02d %02d:%02d:%02d",
            current_time.year, current_time.month, current_time.day,
            current_time.hour, current_time.min, current_time.sec))
        return ""
    end

return osdate