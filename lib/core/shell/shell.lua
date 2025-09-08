local fs = require("filesystem")
local terminal = require("terminal")
local os = require("os")

local shell = {}
    shell.__index = shell

    function shell.new()
        local self = setmetatable({}, shell)
        self.scroll_buffer = _G.scroll_buffer
        self.current_dir = "/home"
        self.saved_dir = {}
        self.access_level = "#"
        self.prompt = self.current_dir .. " # "
        self.commands = {}
        self.command_history = {}
        self:loadHistory()
        self.command_history_index = #self.command_history + 1
        self.aliases = {}
        self:loadAliases()
        return self
    end

    -- Terminate the shell session and clean up RAM
    function shell:terminate()
        _G.scroll_buffer:clear()
        for attribute in pairs(self) do
            self[attribute] = nil
        end
        setmetatable(self, nil)
        _G.shell = nil
    end

    -- Main shell loop
    function shell:run()
        self:clear()
        self:output("Welcome to SolunaOS Shell")
        self:output("Currently in alpha.")
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

    -- Clears the terminal scroll buffer
    function shell:clear()
        self.scroll_buffer:clear()
    end

    -- Resets the command history index to the latest entry
    function shell:resetHistoryIndex()
        self.command_history_index = #self.command_history + 1
    end

    -- Loads command history from log file into shell memory
    function shell:loadHistory()
        local command_history_path = "/etc/logs/command_history.log"
        local file_exists = fs.exists(command_history_path)
        local history = {}
        if file_exists then
            local file = fs.open(command_history_path, "r")
            local content = fs.read(file)
            fs.close(file)
            if content then
                for line in content:gmatch("([^\n]*)\n?") do
                    if line ~= "" then
                        table.insert(history, line)
                    end
                end
            end
        end
        self.command_history = history
    end

    -- Retrieves a specific line from command history by index
    ---@param index number
    ---@return string|nil history_line
    function shell:getHistoryLine(index)
        if self.command_history and index >= 1 and index <= #self.command_history then
            return self.command_history[index]
        end
        return nil
    end

    -- Records a command into history and saves to log file
    ---@param input string
    function shell:recordHistory(input)
        local command_history_path = "/etc/logs/command_history.log"
        local history = self.command_history or {}

        table.insert(history, input)

        while history and #history > 100 do
            table.remove(history, 1)
        end

        self.command_history = history
        local file = fs.open(command_history_path, "w")
        if file then
            for _, line in ipairs(history) do
                fs.write(file, line .. "\n")
            end
            fs.close(file)
        end
    end

    -- Saves the current directory onto the saved stack
    function shell:saveDirectory()
        table.insert(self.saved_dir, self.current_dir)
    end

    -- Pops the last saved directory from the stack and sets as current directory
    ---@return boolean success
    function shell:popSavedDir()
        if self.saved_dir and #self.saved_dir > 0 then
            self.current_dir = self.saved_dir[#self.saved_dir]
            table.remove(self.saved_dir, #self.saved_dir)
            self:updatePrompt(self.current_dir)
            return true
        end
        return false
    end

    -- Get user input with prompt
    --- @param prompt string|nil
    --- @return string prompt
    function shell:input(prompt)
        prompt = self.prompt
        local input = terminal.read(prompt)
        if input and input ~= "" then
            self:recordHistory(input)
        end
        return input
    end

    -- Output text to the terminal
    ---@param text string
    function shell:output(text)
        terminal.writeBuffered(self.scroll_buffer, text)
    end

    -- Update the shell prompt for CLI display
    ---@param prompt string
    function shell:updatePrompt(prompt)
        self.prompt = prompt .. " " .. self.access_level .. " "
    end

    -- Get absolute path from relative path
    ---@param rel_path string
    ---@return string abs_path
    function shell:getAbsPath(rel_path)
        if rel_path:sub(1,1) == "/" then
            return rel_path
        else
            if self.current_dir == "/" then
                return fs.concat("/", rel_path)
            else
                return fs.concat(self.current_dir, rel_path)
            end
        end
    end

    -- Creates an empty command structure
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

    -- Parse user input into command and arguments and sends for tokenization
    ---@param input string
    ---@return any result
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

    -- Splits inputs into tokens for further processing and routing
    ---@param input string
    ---@return table tokens runs again if alias found
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

        if tokens[1] then
            local alias_command = self:resolveAlias(tokens[1])
            if alias_command ~= tokens[1] then
                local actual_command = alias_command
                for j = 2, #tokens do
                    actual_command = actual_command .. " " .. tokens[j]
                end
                return self:tokenizeInput(actual_command)
            end
        end

        return tokens
    end

    -- Handles escaped characters in user input
    ---@param escaped_character string
    ---@return string restored_character
    function shell:handleEscapedCharacter(escaped_character)
        if escaped_character == "n" then
            return "\n"
        elseif escaped_character == "t" then
            return "\t"
        elseif escaped_character == "\r" then
            return "\r"
        else
            return escaped_character
        end
    end

    -- Adds current token to tokens list
    ---@param tokens table
    ---@param token string
    function shell:addToken(tokens, token)
        if token ~= "" then
            table.insert(tokens, token)
        end
        return tokens, ""
    end

    -- Handles special characters like |, ;, <, >, >>, &, && and assigns special functions
    ---@param tokens table current list of tokens
    ---@param in_process_token string current token being processed
    ---@param character string current character being processed
    ---@param input string original input string
    ---@param i number iterator
    function shell:handleSpecialCharacter(tokens, in_process_token, character, input, i)
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
                tokens, in_process_token = self:addToken(tokens, in_process_token)
                if type(special_characters[character]) == "function" then
                    local result, new_i = table.unpack(special_characters[character](input, i))
                    table.insert(tokens, result)
                    return tokens, in_process_token, new_i
                else
                    table.insert(tokens, special_characters[character])
                    return tokens, in_process_token, i
                end
            else
                in_process_token = in_process_token .. character
            end
        return tokens, in_process_token, i
    end

    -- Further processing of tokens to parse out wildcards and variables.
    ---@param tokens table
    ---@return table expanded_tokens
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

    -- Expands environment variables in tokens
    ---@param token string
    ---@return string env_var
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

    -- Expands wildcards in tokens to match filesystem entries
    ---@param pattern string
    ---@return table results
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

    -- Builds out command structure with tokenized inputs.
    ---@param tokens table
    ---@param original_input string
    ---@return table command_structure
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

    -- Checks if the command structure contains pipes
    ---@param commands table
    ---@return boolean yes_no
    function shell:hasPipes(commands)
        return #commands > 1
    end

    -- Checks if the command structure contains redirection
    ---@param commands table
    ---@return boolean yes_no
    function shell:hasRedirects(commands)
        for _, cmd in ipairs(commands) do
            if cmd.output_redirect or cmd.input_redirect then
                return true
            end
        end
        return false
    end

    -- Checks if the command structure contains background execution
    ---@param commands table
    ---@return boolean yes_no
    function shell:hasBackground(commands)
        for _, cmd in ipairs(commands) do
            if cmd.background then
                return true
            end
        end
        return false
    end

    -- Executes the parsed command input by tabulating through the tokens and executing the parameters.
    ---@param parsed_input table
    ---@return string output
    function shell:execute(parsed_input)
        if not parsed_input or not parsed_input.commands then
            return "No command provided"
        end

        local results = {}
        local last_exit_code = 0

        for _, command_structure in ipairs(parsed_input.commands) do
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

    -- Executes a single command without piping
    ---@param command_structure table
    ---@return string output
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

        return output
    end

    -- Executes a series of commands connected by pipes
    ---@param commands table
    ---@return string output
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


    -- Starts a command in the background without blocking the shell inputs
    -- NOT IMPLEMENTED.
    function shell:startBackgroundJob(command_structure)
        self:output("Starting background job: " .. command_structure.command)
    end

    -- Resolves a command alias to its actual command
    function shell:resolveAlias(name)
        if not self.aliases[name] then
            return name
        else
            return self.aliases[name]
        end
    end

    -- Resets all command aliases by clearing /etc/alias.lua and shell memory
    function shell:resetAliases()
        self.aliases = {}
        local file = fs.open("/etc/alias.lua", "w")
        if file then
            fs.write(file, "-- /etc/alias.lua\n\nlocal aliases = {}\n\nreturn aliases")
            fs.close(file)
        end
    end

    -- Removes a command alias from /etc/alias.lua and shell memory
    ---@param name string
    function shell:removeAlias(name)
        self.aliases[name] = nil
        local file = fs.open("/etc/alias.lua", "w")
        if file then
            fs.write(file, "-- /etc/alias.lua\n\nlocal aliases = {}\n\n")
            for alias_name, alias_command in pairs(self.aliases) do
                fs.write(file, string.format("aliases['%s'] = '%s'\n", alias_name, alias_command))
            end
            fs.write(file, "\nreturn aliases")
            fs.close(file)
        end
    end

    -- Saves a command alias to /etc/alias.lua and shell memory
    ---@param name string
    ---@param command string
    function shell:saveAlias(name, command)
        self.aliases[name] = command
        local file = fs.open("/etc/alias.lua", "w")
        if file then
            fs.write(file, "-- /etc/alias.lua\n\nlocal aliases = {}\n\n")
            for alias_name, alias_command in pairs(self.aliases) do
                fs.write(file, string.format("aliases['%s'] = '%s'\n", alias_name, alias_command))
            end
            fs.write(file, "\nreturn aliases")
            fs.close(file)
        end
    end

    -- Loads aliases from /etc/alias.lua into shell memory
    function shell:loadAliases()
        local ok, aliases = pcall(require, "/etc/alias")
        if ok and type(aliases) == "table" then
            self.aliases = aliases
        else
            self.aliases = {}
        end
    end

    -- Loads a command module by name and executes it
    ---@param command_name string
    ---@return table|nil command_module
    function shell:loadCommand(command_name)
        local command_paths = {
        "/lib/core/shell/commands/filesystem",
        "/lib/core/shell/commands/navigation",
        "/lib/core/shell/commands/text",
        "/lib/core/shell/commands/system",
        "/lib/core/shell/commands/environment",
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