local scroll_buffer = _G.scroll_buffer
local fs = require("filesystem")
local terminal = require("terminal")
local os = require("os")

local shell = {}
    shell.__index = shell

    function shell.new()
        local self = setmetatable({}, shell)
        self.scroll_buffer = scroll_buffer
        self.current_dir = "/"
        self.prompt = "SolunaOS # "
        self.commands = {}
        return self
    end

    function shell:terminate()
        self.scroll_buffer:clear()
        for attribute in pairs(self) do
            self[attribute] = nil
        end
        setmetatable(self, nil)
    end

    function shell:run()
        self:output("Welcome to SolunaOS Shell")
        self:output("Currently in alpha.")
        _G.scroll_buffer = self.scroll_buffer
        while true do
            local line = self:input()
            if line then
                local entry = self.prompt .. line
                self:output(entry)
                local parsed_input = self:parseInput(line)
                if parsed_input then
                    local result = self:execute(parsed_input)
                    if result == "exit" then
                        break
                    end
                    self:output(result)
                end
            end
        end
        shell:terminate()
    end

    function shell:input(prompt)
        prompt = self.prompt
        return terminal.read(prompt)
    end

    function shell:output(text)
        terminal.writeBuffered(self.scroll_buffer, text)
    end

    function shell:updatePrompt(prompt)
        self.prompt = prompt
    end

    function shell:parseInput(input)
        if not input or input:match("^%s*$") then
            return nil
        end

        -- Remove whitespace
        input = input:match("^%s*(.-)%s*$")
        local tokens = self:tokenizeInput(input)

        if #tokens == 0 then
            return nil
        end

        tokens = self:expandTokens(tokens)
        return self:parseCommandStructure(tokens, input)
    end

    function shell:tokenizeInput(input)
        local tokens = {}
        local current = ""
        local in_quotes = false
        local quote_character = nil
        local escaped = false
        local i = 1

        while i <= #input do
            local character = input:sub(i,i)

            if escaped then
                current = current .. self:handleEscapedCharacter(character)
                escaped = false
            elseif character == "\\" then
                escaped = true
            elseif not in_quotes then
                if character == '"' or character == "'" then
                    quote_character = character
                    in_quotes = true
                elseif character:match("%s") then
                    tokens, current = self:addToken(tokens, current)
                else
                    tokens, current, i = self:handleSpecialCharacter(tokens, current, character, input, i)
                end
            else
                if character == quote_character then
                    in_quotes = false
                    quote_character = nil
                else
                    current = current .. character
                end
            end
            i = i + 1
        end
        
        if current ~= "" then
            table.insert(tokens, current)
        end
        return tokens
    end

    function shell:handleEscapedCharacter(character)
        if character == "n" then
            return "\n"
        elseif character == "t" then
            return "\t"
        elseif character == "\r" then
            return "\r"
        else
            return character
        end
    end

    function shell:addToken(tokens, current)
        if current ~= "" then
            table.insert(tokens, current)
        end
        return tokens, ""
    end

    function shell:handleSpecialCharacter(tokens, current, character, input, i)
        local special_characters = {
            ['|'] = '|',
            [';'] = ';',
            ['<'] = '<',
            ['>'] = function (input, i)
                return input:sub(i + 1, i + 1) == '>' and {'>>', i + 1} or {'>', i}
            end,
            ['&'] = function(input, i)
                return input:sub(i + 1, i + 1) == "&" and {'&&', i + 1} or {'&', i}
            end
        }
            if special_characters[character] then
                tokens, current = self:addToken(tokens, current)
                if type(special_characters[character]) == "function" then
                    local result, new_i = table.unpack(special_characters[character](input, i))
                    table.insert(tokens, result)
                    return tokens, current, new_i
                else
                    table.insert(tokens, special_characters[character])
                    return tokens, current
                end
            else
                current = current .. character
            end
        return tokens, current, i
    end

    function shell:expandTokens(tokens)
        for i, token in ipairs(tokens) do
            if token:match("%$") then
                tokens[i] = self:expandVariables(token)
            end
            if token:match("[*?]") then
                local expanded = self:expandWildCards(token)
                if #expanded > 1 then
                    table.remove(tokens, i)
                    for j, exp_token in ipairs(expanded) do
                        table.insert(tokens, i + j - 1, exp_token)
                    end
                elseif #expanded == 1 then
                    tokens[i] = expanded[1]
                end
            end
        end
        return tokens
    end

    function shell:expandVariables(token)
        local result = token
        result = result:gsub("%${([^}]+)}", function(variable)
            return os.getenv(variable) or ""
        end)
        result = result:gsub("%$([%w_]+)", function(variable)
            return os.getenv(variable) or ""
        end)
    return result
    end

    function shell:expandWildCards(pattern)
        local results = {}
        local directory = pattern:match("^(.*)/[^/]*$") or self.current_dir

        if fs.exists(directory) and fs.isDirectory(directory) then
            local files = fs.list(directory)
            if type(files) == "table" then
                local match_name = pattern:match("/([^/]*)$") or pattern
                local lua_pattern = "^" .. match_name:gsub("%*", ".*"):gsub("%?", ".") .. "$"
                
                for _, file in ipairs((files)) do
                    if file:match(lua_pattern) then
                        local full_path = directory == "/" and "/" .. file or directory .. "/" .. file
                        table.insert(results, full_path)
                    end
                end
            end
        end
        return #results > 0 and results or {pattern}
    end

    function shell:parseCommandStructure(tokens, original_input)
        local commands = {}
        local current_command = self:createEmptyCommand()
        
        local i = 1
        while i <= #tokens do
            local token = tokens[i]

            if token == "|" then
                if current_command.command then
                    table.insert(commands, current_command)
                end
                current_command = self:createEmptyCommand()
            elseif token == ">" then
                i = i + 1
                if i <= #tokens then
                    current_command.output_redirect = tokens[i]
                    current_command.append_redirect = false
                end
            elseif token == ">>" then
                i = i + 1
                if i <= #tokens then
                    current_command.output_redirect = tokens[i]
                    current_command.append_redirect = true
                end
            elseif token == "<" then
                i = i + 1
                if i <= #tokens then
                    current_command.input_redirect = tokens[i]
                end
            elseif token == "&" then
                current_command.background = true
            elseif token == "&&" then
                if current_command.command then
                    current_command.chain_op = "&&"
                    table.insert(commands, current_command)
                end
                current_command = self:createEmptyCommand()
            elseif token == "||" then
                if current_command.command then
                    current_command.chain_op = "||"
                    table.insert(commands, current_command)
                end
            elseif token == ";" then
                if current_command.command then
                    table.insert(commands, current_command)
                end
                current_command = self:createEmptyCommand()
            else
                if not current_command.command then
                    current_command.command = token
                else
                    table.insert(current_command.args, token)
                end
            end
            i = i + 1
        end
        
        if current_command.command then
            table.insert(commands, current_command)
        end
        return {
            commands = commands,
            original_input = original_input,
            has_pipes = self:hasPipes(commands),
            has_redirection = self:hasRedirects(commands),
            has_background = self:hasBackground(commands),
        }
    end

    function shell:createEmptyCommand()
        return {
            command = nil,
            args = {},
            output_redirect = nil,
            append_redirect = false,
            input_redirect = nil,
            background = false,
            chain_op = nil,
        }
    end

    function shell:hasPipes(commands)
        return #commands > 1
    end

    function shell:hasRedirects(commands)
        for _, cmd in ipairs(commands) do
            if cmd.output_redirect or cmd.input_redirect then
                return true
            end
        end
        return false
    end

    function shell:hasBackground(commands)
        for _, cmd in ipairs(commands) do
            if cmd.background then
                return true
            end
        end
        return false
    end

    function shell:execute(parsed_input)
        if not parsed_input or not parsed_input.commands then
            return "No command provided"
        end

        local results = {}
        local last_exit_code = 0

        for i, command_structure in ipairs(parsed_input.commands) do
            local should_execute = true

            if command_structure.chain_op then
                if command_structure.chain_op == "&&" and last_exit_code ~= 0 then
                    should_execute = false
                elseif command_structure.chain_op == "||" and last_exit_code == 0 then
                    should_execute = false
                end
            end

            if should_execute then
                if parsed_input.has_pipes and #parsed_input.commands > 1 then
                    local result = self:executePipeline(parsed_input.commands)
                    table.insert(results, result)
                    break
                else
                    local result, exit_code = self:executeSingleCommand(command_structure)
                    table.insert(results, result)
                    last_exit_code = exit_code or 0

                    if command_structure.background then
                        self:startBackgroundJob(command_structure)
                    end
                end
            end
        end
        return table.concat(results, "\n")
    end

    function shell:executeSingleCommand(command_structure)
        local command = command_structure.command
        local args = command_structure.args

        local input_data = nil
        if command_structure.input_redirect then
            local file = fs.open(command_structure.input_redirect, "r")
            if file then
                input_data = fs.read(file)
                fs.close(file)
            else
                return "Error: Unable to open input file " .. command_structure.input_redirect, 1
            end
        end

        local output = ""
        if self.commands[command] then
            output = self.commands[command](args, input_data) or ""
        else
            local command_module = self:loadCommand(command)
            if command_module then
                output = command_module.execute(args, input_data, self) or ""
            else
                return "Error: Command '" .. command .. "' not found", 1
            end
        end

        if command_structure.output_redirect then
            local mode = command_structure.append_redirect and "a" or "w"
            local file = fs.open(command_structure.output_redirect, mode)
            if file then
                fs.write(file, output)
                fs.close(file)
                return "Output written to " .. command_structure.output_redirect, 0
            else
                return "Error: Cannot write to " .. command_structure.output_redirect, 1
            end
        end

        return output, 0
    end

    function shell:executePipeline(commands)
        local data = ""

        for i, command in ipairs(commands) do
            if i == 1 then
                data = self:executeSingleCommand(command)
            else
                if self.commands[command.command] then
                    data = self.commands[command.command](command.args, data) or ""
                else
                    return "Error: Command '" .. command.command .. "' not found"
                end
            end
        end
        return data
    end

    function shell:startBackgroundJob(command_structure)
        self:output("Starting background job: " .. command_structure.command)
    end

    function shell:loadCommand(command_name)
        local command_paths = {
        "/lib/core/shell/commands/filesystem",
        "/lib/core/shell/commands/navigation", 
        "/lib/core/shell/commands/text",
        "/lib/core/shell/commands/system",
        "/lib/core/shell/commands/environment",
        "/lib/core/shell/commands/io",
        "/lib/core/shell/commands/network",
        "/lib/core/shell/commands/sh",
        "/lib/core/shell/commands/misc",
       }
        
       for _, path in ipairs(command_paths) do
            local full_module_path = path .. "/" .. command_name
            local ok, command_module = pcall(require, full_module_path)
            if ok and command_module and command_module.execute then
                self.commands[command_name] = function(args, input_data)
                    return command_module.execute(args, input_data, self)
                end
                return command_module
            end
        end
        return nil
    end
       
return shell