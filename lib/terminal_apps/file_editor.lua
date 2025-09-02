-- /lib/terminal_apps/file_editor.lua
local fs = require("filesystem")
local scroll_buffer = require("scroll_buffer")
local event = _G.event
local keyboard = _G.keyboard
local cursor = _G.cursor
local draw = require("draw")

local help_text = "Ctrl+S: Save | Ctrl+W: Close | Ctrl+F: Find | Ctrl+K: Cut | Ctrl+U: Uncut"

local file_editor = {}
    file_editor.__index = file_editor

    function file_editor.new()
        local self = setmetatable({}, file_editor)
        self.editor_buffer = scroll_buffer.new()
        self.editor_buffer:fileEditorMode()
        self.filepath = ""
        self.filename = ""
        self.new_file = false
        self.file_saved = false
        self.save_error = false
        self.find_buffer = ""
        self.find_iterator = 1
        cursor:setPosition(1, 1)
        return self
    end

    function file_editor:terminate()
        self.editor_buffer:terminate()
        for attribute in pairs(self) do
            self[attribute] = nil -- Clear methods to free up memory
        end
        setmetatable(self, nil)
    end

    function file_editor:run(filepath)
        local filename = fs.getNameFromPath(filepath)
        local buffer = self.editor_buffer
        self.filepath = filepath
        self.filename = filename
        draw.clear()
        if fs.exists(filepath) then
            self.editor_buffer:loadFromFile(filepath)
            self:renderCurrentStatus()
        else
            local file, err = fs.open(filepath, "w")
            fs.close(file)
            self.new_file = true
            self:renderTopLine("New file: " .. filename)
            self:renderBottomLine(help_text)
        end

        self:edit()
        if self.new_file and not self.file_saved then
            fs.remove(filepath)
        end
        self:terminate()
        draw.clear()
    end

    function file_editor:input()
        local character
        local output
        while character == nil do
            cursor:show()
            output = event:listen(0.5)
            if output ~= nil and type(output) == "string" then
                character = output
                cursor:show()
                break
            end
            cursor:hide()
            output = event:listen(0.5)
            if output ~= nil and type(output) == "string" then
                character = output
                cursor:show()
                break
            end
        end
        return character
    end

    function file_editor:edit()
        while true do
            local character = self:input()
            if character == "\n" then
                self.editor_buffer:newLine()
            elseif character == "\t" then
                self.editor_buffer:insertCharacter("    ")
            elseif character == "\b" then
                self.editor_buffer:backspace()
            elseif character == "del" then
                self.editor_buffer:delete()
            elseif character == "<-" then
                self.editor_buffer:moveCursorLeft()
            elseif character == "->" then
                self.editor_buffer:moveCursorRight()
            elseif character == "\\^" then
                self.editor_buffer:moveCursorUp()
            elseif character == "\\v" then
                self.editor_buffer:moveCursorDown()
            elseif character == "s" and keyboard:getCtrl() then
                local ok = self.editor_buffer:saveToFile(self.filepath)
                if ok then
                    self.file_saved = true
                else
                    self.save_error = true
                end
            elseif character == "w" and keyboard:getCtrl() then
                break
            elseif character == "f" and keyboard:getCtrl() then
                self:findMode()
            elseif #character == 1 then
                self.editor_buffer:insertCharacter(character)
            end
            local x_pos, y_pos = self.editor_buffer:getCursorPosition()
            cursor:setPosition(x_pos, y_pos)
            if self.file_saved then
                self:renderTopLine("File saved: " .. self.filename)
                self:renderBottomLine(help_text)
                self.file_saved = false
            elseif not self.save_error then
                self:renderCurrentStatus()
            else
                self:renderTopLine("Error saving " .. self.filename)
                self:renderBottomLine(help_text)
                self.save_error = false
            end
        end
    end
    
    function file_editor:renderTopLine(string)
        local height = _G.height
        draw.termText(string, 1, height - 1)
    end
    function file_editor:renderBottomLine(string)
        local height = _G.height
        draw.termText(string, 1, height)
    end

    function file_editor:renderCurrentStatus()
        local filename = self.filename
        local total_lines = self.editor_buffer:getTotalLines()
        local total_characters = self.editor_buffer:getTotalCharacters()
        local current_line = self.editor_buffer:getCurrentLine()
        local current_column = self.editor_buffer:getCurrentColumn()
        local file_size = self.editor_buffer:getFileSize()

        local status = filename .. " | " .. total_lines .. "L" .. " " .. total_characters .. "C" .. " | Ln " .. current_line .. ", Col " .. current_column .. " | " .. file_size
        self:renderTopLine(status)
        self:renderBottomLine(help_text)
    end

    function file_editor:findMode()
        local height = _G.height
        local find_string = "Find text: " .. self.find_buffer
        self:renderTopLine(find_string)
        self:renderBottomLine("Find mode: enter search term (Ctrl+C to exit)")
        cursor:setPosition(#find_string + 1, height - 1)
        while true do
            local character = self:input()
            if character == "c" and keyboard:getCtrl() then
                break
            elseif character == "\b" then
                if #self.find_buffer > 0 then
                    self.find_buffer = self.find_buffer:sub(1, -2)
                end
            elseif character == "\n" then
                self.find_iterator = self.find_iterator + 1
            elseif #character == 1 then
                self.find_buffer = self.find_buffer .. character
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
            self:renderTopLine(find_string .. " " .. report_string)
            self:renderBottomLine("Find mode: enter search term (Ctrl+C to exit)")
            cursor:setPosition(#find_string + 1, height - 1)
        end
    end

    return file_editor
