-- /lib/core/shell/shell.lua

local fs = require("filesystem")
local terminal = require("terminal")

local shell = {}
shell.__index = shell

function shell.new(scroll_buffer)
    local self = setmetatable({}, shell)
    self.scroll_buffer = scroll_buffer or _G.scroll_buffer
    self.current_dir = "/home"
    self.saved_dir = {}
    self.access_lvl = "#"
    self.prompt = self.current_dir .. " # "
    self.cmds = {}
    self.cmd_hist = {}
    self:loadHistory()
    self.cmd_hist_index = #self.cmd_hist + 1
    self.aliases = {}
    self:loadAliases()
    return self
end

-- Terminate shell object and clear memory
function shell:terminate()
    self.scroll_buffer:clear()
    for attribute in pairs(self) do
        self[attribute] = nil
    end
    setmetatable(self, nil)
end

-- Main shell loop
function shell:run()
    self:clear()
    self:output("Welcome to SolunaOS Shell")
    self:output("Currently in alpha.")

    while true do
        local prompt = self.prompt
        local line = self:input()
        if line and #line ~= #prompt then
            local entry = prompt .. line
            self:output(entry)
            local parsed_input = self:parseInput(line)
            if parsed_input then
                local result = self:execute(parsed_input)
                if result == "exit" then
                    break
                end
                self:output(result)
            end
        elseif line and #line == #prompt then
            self:output(line)
        else
            break
        end
    end
    shell:terminate()
end

-- Clears the terminal
function shell:clear()
    self.scroll_buffer:clear()
end

-- Resets the command history index to the latest entry
function shell:resetHistoryIndex()
    self.cmd_hist_index = #self.cmd_hist + 1
end

-- Loads command history from log file into shell memory
function shell:loadHistory()
    local cmd_hist_path = "/etc/logs/command_history.log"
    local file_exists = fs.exists(cmd_hist_path)
    local hist = {}
    if file_exists then
        local file = fs.open(cmd_hist_path, "r")
        local content = fs.read(file)
        fs.close(file)
        if content then
            for line in content:gmatch("([^\n]*)\n?") do
                if line ~= "" then
                    table.insert(hist, line)
                end
            end
        end
    end
    self.cmd_hist = hist
end

-- Retrieves a specific line from command history by index
---@param index number
---@return string|nil history_line
function shell:getHistoryLine(index)
    if self.cmd_hist and index >= 1 and index <= #self.cmd_hist then
        return self.cmd_hist[index]
    end
    return nil
end

-- Records a command into history and saves to log file
---@param input string
function shell:recordHistory(input)
    local cmd_hist_path = "/etc/logs/command_history.log"
    local hist = self.cmd_hist

    table.insert(hist, input)

    while #hist > 100 do
        table.remove(hist, 1)
    end
    self.cmd_hist = hist

    local hist_snapshot = table.concat(hist, "\n")

    if hist_snapshot ~= self.last_hist_snapshot then
        local file = fs.open(cmd_hist_path, "w")
        if file then
            fs.write(file, hist_snapshot .. "\n")
            fs.close(file)
        end
        self.last_hist_snapshot = hist_snapshot
    end
end

-- Saves the current dir onto the saved stack
function shell:saveDirectory()
    table.insert(self.saved_dir, self.current_dir)
end

-- Pops the last saved dir from the stack and sets as current dir
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
    prompt = prompt or self.prompt
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
    self.prompt = prompt .. " " .. self.access_lvl .. " "
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
        cmd = nil,
        args = {},
        output_redir = nil,
        append_redir = false,
        input_redir = nil,
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
    local current = {}
    local in_quotes = false
    local quote_char = nil
    local escaped = false
    local i = 1

    while i <= #input do
        local char = input:sub(i, i)

        if escaped then
            table.insert(current, self:handleEscapedCharacter(char))
            escaped = false
        elseif char == "\\" then
            escaped = true
        elseif not in_quotes then
            if char == '"' or char == "'" then
                quote_char = char
                in_quotes = true
            elseif char:match("%s") then
                if #current > 0 then
                    table.insert(tokens, table.concat(current))
                    current = {}
                end
            else
                local new_tokens, new_current, new_i = self:handleSpecialCharacter(tokens, table.concat(current), char, input, i)
                tokens = new_tokens
                current = {}
                if new_current ~= "" then
                    for character in new_current:gmatch(".") do
                        table.insert(current, character)
                    end
                end
            i = new_i
            end
        else
            if char == quote_char then
                in_quotes = false
                quote_char = nil
            else
                table.insert(current, char)
            end
        end
        i = i + 1
    end

    if #current > 0 then
        table.insert(tokens, table.concat(current))
    end

    if tokens[1] then
        local alias_cmd = self:resolveAlias(tokens[1])
        if alias_cmd ~= tokens[1] then
            local actual_cmd = alias_cmd
            for j = 2, #tokens do
                actual_cmd = actual_cmd .. " " .. tokens[j]
            end
            return self:tokenizeInput(table.concat(actual_cmd, " "))
        end
    end

    return tokens
end

-- Handles escaped characters in user input
---@param esc_char string
---@return string restored_character
function shell:handleEscapedCharacter(esc_char)
    local escapes = {
        n = "\n",
        t = "\t",
        r = "\r"
    }
    return escapes[esc_char] or esc_char
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

local SPECIAL_CHARS = {
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

-- Handles special characters like |, ;, <, >, >>, &, && and assigns special functions
---@param tokens table current list of tokens
---@param in_process_token string current token being processed
---@param char string current character being processed
---@param input string original input string
---@param i number iterator
function shell:handleSpecialCharacter(tokens, in_process_token, char, input, i)
    local handler = SPECIAL_CHARS[char]
    if handler then
        tokens, in_process_token = self:addToken(tokens, in_process_token)
        if type(handler) == "function" then
            local result, new_i = table.unpack(handler(input, i))
            table.insert(tokens, result)
            return tokens, in_process_token, new_i
        else
            table.insert(tokens, handler)
            return tokens, in_process_token, i
        end
    else
        in_process_token = in_process_token .. char
    end
    return tokens, in_process_token, i
end

-- Further processing of tokens to parse out wildcards and variables.
---@param tokens table
---@return table expanded_tokens
function shell:expandTokens(tokens)
    local expanded_tokens = {}
    for _, token in ipairs(tokens) do
        if token:match("[*?]") then
            local expanded = self:expandWildCards(token)
            for _, exp_token in ipairs(expanded) do
                table.insert(expanded_tokens, exp_token)
            end
        else
            table.insert(expanded_tokens, token)
        end
    end
    return expanded_tokens
end

-- Expands wildcards in tokens to match filesystem entries
---@param pattern string
---@return table results
function shell:expandWildCards(pattern)
    local results = {}
    local dir = pattern:match("^(.*)/[^/]*$") or self.current_dir

    if fs.exists(dir) and fs.isDirectory(dir) then
        local files = fs.list(dir)
        if type(files) == "table" then
            local match_name = pattern:match("/([^/]*)$") or pattern
            local lua_pattern = "^" .. match_name:gsub("%*", ".*"):gsub("%?", ".") .. "$"

            for _, file in ipairs(files) do
                if file:match(lua_pattern) then
                    local full_path
                    if dir == "/" then
                        full_path = "/" .. file
                    else
                        full_path = dir .. "/" .. file
                    end
                    table.insert(results, full_path)
                end
            end
        end
    end
    return #results > 0 and results or {pattern}
end

-- Builds out command structure with tokenized inputs.
---@param tokens table
---@param og_input string original input
---@return table cmd_struct
function shell:parseCommandStructure(tokens, og_input)
    local cmds = {}
    local current_cmd = self:createEmptyCommand()

    local i = 1
    while i <= #tokens do
        local token = tokens[i]

        if token == "|" then
            if current_cmd.cmd then
                table.insert(cmds, current_cmd)
            end
            current_cmd = self:createEmptyCommand()
        elseif token == ">" then
            i = i + 1
            if i <= #tokens then
                current_cmd.output_redir = tokens[i]
                current_cmd.append_redir = false
            end
        elseif token == ">>" then
            i = i + 1
            if i <= #tokens then
                current_cmd.output_redir = tokens[i]
                current_cmd.append_redir = true
            end
        elseif token == "<" then
            i = i + 1
            if i <= #tokens then
                current_cmd.input_redir = tokens[i]
            end
        elseif token == "&" then
            current_cmd.background = true
        elseif token == "&&" then
            if current_cmd.cmd then
                current_cmd.chain_op = "&&"
                table.insert(cmds, current_cmd)
            end
            current_cmd = self:createEmptyCommand()
        elseif token == "||" then
            if current_cmd.cmd then
                current_cmd.chain_op = "||"
                table.insert(cmds, current_cmd)
            end
        elseif token == ";" then
            if current_cmd.cmd then
                table.insert(cmds, current_cmd)
            end
            current_cmd = self:createEmptyCommand()
        else
            if not current_cmd.cmd then
                current_cmd.cmd = token
            else
                table.insert(current_cmd.args, token)
            end
        end
        i = i + 1
    end

    if current_cmd.cmd then
        table.insert(cmds, current_cmd)
    end
    return {
        cmds = cmds,
        original_input = og_input,
        has_pipes = self:hasPipes(cmds),
        has_redirection = self:hasRedirects(cmds),
        has_background = self:hasBackground(cmds),
    }
end

-- Checks if the command structure contains pipes
---@param cmds table
---@return boolean yes_no
function shell:hasPipes(cmds)
    return #cmds > 1
end

-- Checks if the command structure contains redirection
---@param cmds table
---@return boolean yes_no
function shell:hasRedirects(cmds)
    for _, cmd in ipairs(cmds) do
        if cmd.output_redir or cmd.input_redir then
            return true
        end
    end
    return false
end

-- Checks if the command structure contains background execution
---@param cmds table
---@return boolean yes_no
function shell:hasBackground(cmds)
    for _, cmd in ipairs(cmds) do
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
    if not parsed_input or not parsed_input.cmds then
        return "No command provided"
    end

    local results = {}
    local last_exit_code = 0

    for _, cmd_struct in ipairs(parsed_input.cmds) do
        local should_execute = true

        if cmd_struct.chain_op then
            if cmd_struct.chain_op == "&&" and last_exit_code ~= 0 then
                should_execute = false
            elseif cmd_struct.chain_op == "||" and last_exit_code == 0 then
                should_execute = false
            end
        end

        if should_execute then
            if parsed_input.has_pipes and #parsed_input.cmds > 1 then
                local result = self:executePipeline(parsed_input.cmds)
                table.insert(results, result)
                break
            else
                local result, exit_code = self:executeSingleCommand(cmd_struct)
                table.insert(results, result)
                last_exit_code = exit_code or 0

                if cmd_struct.background then
                    self:startBackgroundJob(cmd_struct)
                end
            end
        end
    end
    return table.concat(results, "\n")
end

-- Executes a single command without piping
---@param cmd_struct table
---@return string output
function shell:executeSingleCommand(cmd_struct)
    local cmd = cmd_struct.cmd
    local args = cmd_struct.args

    local input_data = nil
    if cmd_struct.input_redir then
        local file = fs.open(cmd_struct.input_redir, "r")
        if file then
            input_data = fs.read(file)
            fs.close(file)
        else
            return "Error: Unable to open input file " .. cmd_struct.input_redir, 1
        end
    end

    local output = ""
    if self.cmds[cmd] then
        output = self.cmds[cmd](args, input_data) or ""
    else
        local cmd_mod = self:loadCommand(cmd)
        if cmd_mod then
            output = cmd_mod.execute(args, input_data, self) or ""
        else
            return "Error: Command '" .. cmd .. "' not found", 1
        end
    end

    if cmd_struct.output_redir then
        local mode = cmd_struct.append_redir and "a" or "w"
        local file = fs.open(cmd_struct.output_redir, mode)
        if file then
            fs.write(file, output)
            fs.close(file)
            return "Output written to " .. cmd_struct.output_redir, 0
        else
            return "Error: Cannot write to " .. cmd_struct.output_redir, 1
        end
    end

    return output
end

-- Executes a series of commands connected by pipes
---@param cmds table
---@return string output
function shell:executePipeline(cmds)
    local data = ""

    for i, cmd in ipairs(cmds) do
        if i == 1 then
            data = self:executeSingleCommand(cmd)
        else
            if self.cmds[cmd.cmd] then
                data = self.cmds[cmd.cmd](cmd.args, data) or ""
            else
                return "Error: Command '" .. cmd.cmd .. "' not found"
            end
        end
    end
    return data
end


-- Starts a command in the background without blocking the shell inputs
-- NOT IMPLEMENTED.
function shell:startBackgroundJob(cmd_struct)
    self:output("Starting background job: " .. cmd_struct.cmd)
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
        for alias_name, alias_cmd in pairs(self.aliases) do
            fs.write(file, string.format("aliases['%s'] = '%s'\n", alias_name, alias_cmd))
        end
        fs.write(file, "\nreturn aliases")
        fs.close(file)
    end
end

-- Saves a command alias to /etc/alias.lua and shell memory
---@param name string
---@param cmd string
function shell:saveAlias(name, cmd)
    self.aliases[name] = cmd
    local file = fs.open("/etc/alias.lua", "w")
    if file then
        fs.write(file, "-- /etc/alias.lua\n\nlocal aliases = {}\n\n")
        for alias_name, alias_cmd in pairs(self.aliases) do
            fs.write(file, string.format("aliases['%s'] = '%s'\n", alias_name, alias_cmd))
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

local COMMAND_PATHS = {
    "/lib/core/shell/commands/filesystem",
    "/lib/core/shell/commands/navigation",
    "/lib/core/shell/commands/text",
    "/lib/core/shell/commands/system",
    "/lib/core/shell/commands/environment",
    "/lib/core/shell/commands/network",
    "/lib/core/shell/commands/sh",
    "/lib/core/shell/commands/misc",
    }

-- Loads a command module by name and executes it
---@param cmd_name string
---@return table|nil command_module
function shell:loadCommand(cmd_name)
    for _, path in ipairs(COMMAND_PATHS) do
        local full_module_path = path .. "/" .. cmd_name
        local ok, cmd_mod = pcall(require, full_module_path)
        if ok and cmd_mod and cmd_mod.execute then
            self.cmds[cmd_name] = function(args, input_data)
                return cmd_mod.execute(args, input_data, self)
            end
            return cmd_mod
        end
    end
    return nil
end

return shell