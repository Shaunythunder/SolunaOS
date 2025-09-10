-- lib/core/shell/commands/text/grep.lua

local fs = require("filesystem")

local grep = {}
grep.description = "Searches for patterns in text"
grep.usage = "Usage: grep [flags] <pattern> [file...]"
grep.flags = {
    i = "Ignore case distinctions",
    v = "Invert the sense of matching, to select non-matching lines",
    n = "Prefix each line of output with the line number within its input file",
    F = "Interpret pattern as a fixed string, not a regular expression",
    c = "Print only a count of matching lines per input file"
}

    function grep.findInText(input_data, pattern, case_sensitive, invert, show_line_numbers, fixed_string, count_only)
        local lines = {}
        for line in input_data:gmatch("([^\n]*)\n?") do
            table.insert(lines, line)
        end

        local match_count = 0

        if not case_sensitive and not fixed_string then
            pattern = pattern:lower()
        end

        for line_num, line in ipairs(lines) do
            local search_line = line
            local test_pattern = pattern

            if not case_sensitive and not fixed_string then
                search_line = line:lower()
                test_pattern = pattern:lower()
            end

            local matches
            if fixed_string then
                matches = search_line:find(test_pattern, 1, true) ~= nil
            else
                local function searchLine(search_line, test_pattern)
                    return search_line:find(test_pattern) ~= nil
                end

                local success, result = pcall(searchLine, search_line, test_pattern)

                if not success then
                    print("grep: invalid pattern")
                    return
                else
                    matches = result
                end
            end
            
            if (matches and not invert) or (not matches and invert) then
                match_count = match_count + 1
                if not count_only then
                    local output_line = ""
                    if show_line_numbers then
                        output_line = tostring(line_num) .. ":"
                    end
                    output_line = output_line .. line
                    print(output_line)
                end
            end
        end
        if count_only then
            print(tostring(match_count))
        end
    end

    function grep.printUsage()
        print(grep.usage)
        print("Flags:")
        for flag in pairs(grep.flags) do
            local description = grep.flags[flag]
            print("-" .. flag .. ": " .. description)
        end
    end

    function grep.execute(args, input_data, _)
        if #args == 0 then
            grep.printUsage()
            return ""
        end

        local pattern = nil
        local files = {}
        local case_sensitive = true
        local invert = false
        local show_line_numbers = false
        local fixed_string = false
        local count_only = false

        local i = 1
        while i <= #args do
            local arg = args[i]
            if arg:sub(1, 1) == "-" then
                local flags = arg:sub(2)
                for j = 1, #flags do
                    local flag = flags:sub(j, j)
                    if flag == "i" then
                        case_sensitive = false
                    elseif flag == "v" then
                        invert = true
                    elseif flag == "n" then
                        show_line_numbers = true
                    elseif flag == "F" then
                        fixed_string = true
                    elseif flag == "c" then
                        count_only = true
                    end
                end
            elseif not pattern then
                pattern = arg
            else
                table.insert(files, arg)
            end
            i = i + 1
        end

        if not pattern then
            grep.printUsage()
            return ""
        end

        if #files == 0 then
            if input_data then
                grep.findInText(input_data, pattern, case_sensitive, invert, show_line_numbers, fixed_string, count_only)
            else
                grep.printUsage()
                return ""
            end
        else
            for _, filename in ipairs(files) do
                if fs.exists(filename) then
                    local file = fs.open(filename, "r")
                    if file then
                        local content = fs.read(file) or ""
                        fs.close(file)
                        grep.findInText(content, pattern, case_sensitive, invert, show_line_numbers, fixed_string, count_only)
                    else
                        print("cannot open file: " .. filename)
                    end
                else
                    print("grep: " .. filename .. ": No such file or directory")
                end
            end
        end
    end

return grep