-- /lib/core/shell/commands/filesystem/find.lua

local fs = require("filesystem")

local find = {}
find.description = "Find files by name or pattern. Accepts wildcards * and ?"
find.usage = "Usage: find <filename or pattern>"
find.flags = {}

    function find.execute(args, _, _)
        if #args ~= 1 then
            return find.usage
        end

        local wildcard_target = args[1]

        wildcard_target = wildcard_target:gsub("%.", "%%."):gsub("%*", ".*"):gsub("%?", ".")

        local found_paths = {}

        local function recursiveSearch(abs_path)
            local files = fs.list(abs_path)
            if not files then
                return
            end
            for _, file in ipairs(files) do
                local full_path = fs.concat(abs_path, file)
                local is_dir = fs.isDirectory(full_path)
                if file:match ("^" .. wildcard_target .. "$") then
                    table.insert(found_paths, full_path)
                end
                if is_dir then
                    recursiveSearch(full_path)
                end
            end
        end

        recursiveSearch("/")

        if #found_paths == 0 then
            return "No files found with name: " .. args[1]
        else
            return table.concat(found_paths, "\n")
        end
    end

return find