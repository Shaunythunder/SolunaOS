-- lib/core/shell/commands/navigation/popd.lua

local popd = {}
popd.description = "Returns to the last saved directory"
popd.usage = "Usage: popd"
popd.flags = {}

    -- This command returns to the last saved directory.
    function popd.execute(args, input_data, shell)
        if #args ~= 0 then
            return popd.usage
        end
        local success = shell:popSavedDir()
        if not success then
            return "Saved directory stack is empty"
        end
        return ""
    end

return popd