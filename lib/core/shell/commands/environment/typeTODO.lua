-- lib/core/shell/commands/environment/type.lua

local type = {}

    -- Displays the type of a given argument
    function type.execute(args, input_data, shell)
        if #args ~= 1 then
            return "Usage: type [-a] [command]"
        end

        local arg = args[1]
        local arg_type = type(arg)

        return arg_type
    end