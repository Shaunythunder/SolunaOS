-- /lib/terminal_apps/file_editor.lua
local fs = require("filesystem")
local editor_buffer = require("scroll_buffer")
local event = _G.event
local keyboard = _G.keyboard
local draw = require("draw")

local help_text = "Ctrl+S: Save | Ctrl+W: Close | Ctrl+F: Find | Ctrl+K: Cut | Ctrl+U: Uncut"

local file_editor = {}
file_editor.__index = file_editor

function file_editor.new(height, cursor)
    local self = setmetatable({}, file_editor)
    self.height = height or _G.height
    self.cursor = cursor or _G.cursor
    self.editor_buffer = editor_buffer.new()
    self.editor_buffer:fileEditorMode()
    self.filepath = ""
    self.filename = ""
    self.new_file = false
    self.file_saved = false
    self.save_err = false
    self.find_buffer = ""
    self.find_iterator = 1
    self.cut_buffer = ""
    self.cursor:setPosition(1, 1)
    return self
end

-- Cleans up the editor instance
function file_editor:terminate()
    self.editor_buffer:terminate()
    for attribute in pairs(self) do
        self[attribute] = nil -- Clear methods to free up memory
    end
    setmetatable(self, nil)
end

-- Main run loop for the file editor
--- @param filepath string
function file_editor:run(filepath)
    local filename = fs.getNameFromPath(filepath)
    local buffer = self.editor_buffer
    self.filepath = filepath
    self.filename = filename
    draw.clear()
    if fs.exists(filepath) then
        buffer:loadFromFile(filepath)
        self:renderCurrentStatus()
    else
        local file, _ = fs.open(filepath, "w")
        fs.close(file)
        self.new_file = true
        buffer:renderTopLine("New file: " .. filename)
        buffer:renderBottomLine(help_text)
    end

    self:edit()
    if self.new_file and not self.file_saved then
        fs.remove(filepath)
    end
    self:terminate()
    draw.clear()
end

-- Handles user input in the editor
function file_editor:input()
    local char
    local output
    while char == nil do
        self.cursor:show()
        output = event:listen(0.5)
        if output ~= nil and type(output) == "string" then
            char = output
            self.cursor:show()
            break
        end
        self.cursor:hide()
        output = event:listen(0.5)
        if output ~= nil and type(output) == "string" then
            char = output
            self.cursor:show()
            break
        end
    end
    return char
end

-- Main editing loop
function file_editor:edit()
    while true do
        local char = self:input()
        if char == "\n" then
            self.editor_buffer:newLine()
        elseif char == "\t" then
            self.editor_buffer:insertCharacter("    ")
        elseif char == "\b" then
            self.editor_buffer:backspace()
        elseif char == "del" then
            self.editor_buffer:delete()
        elseif char == "<-" then
            self.editor_buffer:moveCursorLeft()
        elseif char == "->" then
            self.editor_buffer:moveCursorRight()
        elseif char == "\\^" then
            self.editor_buffer:moveCursorUp()
        elseif char == "\\v" then
            self.editor_buffer:moveCursorDown()
        elseif char == "s" and keyboard:getCtrl() then
            local ok = self.editor_buffer:saveToFile(self.filepath)
            if ok then
                self.file_saved = true
            else
                self.save_err = true
            end
        elseif char == "w" and keyboard:getCtrl() then
            break
        elseif char == "f" and keyboard:getCtrl() then
            self:findMode()
        elseif char == "k" and keyboard:getCtrl() then
            self.cut_buffer = self.editor_buffer:cutLine()
        elseif char == "u" and keyboard:getCtrl() then
            if self.cut_buffer and self.cut_buffer ~= "" then
                self.editor_buffer:uncutLine(self.cut_buffer)
            end
        elseif #char == 1 then
            self.editor_buffer:insertCharacter(char)
        end
        local x_pos, y_pos = self.editor_buffer:getCursorPosition()
        self.cursor:setPosition(x_pos, y_pos)
        if self.file_saved then
            self.editor_buffer:renderTopLine("File saved: " .. self.filename)
            self.editor_buffer:renderBottomLine(help_text)
            self.file_saved = false
        elseif not self.save_err then
            self:renderCurrentStatus()
        else
            self.editor_buffer:renderTopLine("Error saving " .. self.filename)
            self.editor_buffer:renderBottomLine(help_text)
            self.save_err = false
        end
    end
end

-- Clamps whitespace for status line formatting
--- @param value any
--- @param length number|nil
function file_editor:clampWhitespace(value, length)
    length = length or 4
    local text = tostring(value)
    if #text < length then
        if #text == 0 then
            return string.rep(" ", length)
        else
            return text .. string.rep(" ", length - #text)
        end
    end
    return text
end

-- Renders the current status line
function file_editor:renderCurrentStatus()
    local filename = self.filename
    local total_lines = self.editor_buffer:getTotalLines()
    local total_characters = self.editor_buffer:getTotalCharacters()
    local current_line = self.editor_buffer:getCurrentLine()
    local current_column = self.editor_buffer:getCurrentColumn()
    local file_size = self.editor_buffer:getFileSize()
    current_line = self:clampWhitespace(current_line)
    current_column = self:clampWhitespace(current_column, 2)

    local status = filename .. " | " .. total_lines .. "L" .. " | " .. total_characters .. "C" .. " | Ln " .. current_line .. "| Col " .. current_column .. " | " .. file_size
    self.editor_buffer:renderTopLine(status)
    self.editor_buffer:renderBottomLine(help_text)
end

-- Handles find mode functionality
function file_editor:findMode()
    local h = self.height
    local find_string = "Find text: " .. self.find_buffer
    self.editor_buffer:renderTopLine(find_string)
    self.editor_buffer:renderBottomLine("Find mode: enter search term (Ctrl+C to exit)")
    self.cursor:setPosition(#find_string + 1, h - 1)
    while true do
        local char = self:input()
        if char == "c" and keyboard:getCtrl() then
            break
        elseif char == "\b" then
            if #self.find_buffer > 0 then
                self.find_buffer = self.find_buffer:sub(1, -2)
            end
        elseif char == "\n" then
            self.find_iterator = self.find_iterator + 1
        elseif #char == 1 then
            self.find_buffer = self.find_buffer .. char
        end
        local results = self.editor_buffer:findText(self.find_buffer)
        if self.find_iterator > #results then
            self.find_iterator = 1
        end
        self.editor_buffer:scrollToText(results, self.find_iterator)
        self.editor_buffer:highlightText(self.find_buffer, results, self.find_iterator)
        local find_string = "Find text: " .. self.find_buffer
        local report_string = "(" .. self.find_iterator .. "/" .. #results .. ")"
        if #results == 0 then
            report_string = " No results"
            self.editor_buffer:updateVisibleEditor()
        end
        self.editor_buffer:renderTopLine(find_string .. " " .. report_string)
        self.editor_buffer:renderBottomLine("Find mode: enter search term (Ctrl+C to exit)")
        self.cursor:setPosition(#find_string + 1, h - 1)
    end
end

return file_editor
