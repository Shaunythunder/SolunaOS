-- /lib/terminal_apps/file_editor.lua
local fs = require("filesystem")
local scroll_buffer = require("scroll_buffer")
local event = _G.event
local keyboard = _G.keyboard
local cursor = _G.cursor

local file_editor = {}
    file_editor.__index = file_editor

    function file_editor.new()
        local self = setmetatable({}, file_editor)
        self.editor_buffer = scroll_buffer.new()
        self.editor_buffer:fileEditorMode()
        self.filepath = ""
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
        self.filepath = filepath
        if fs.exists(filepath) then
            self.editor_buffer:loadFromFile(filepath)
        else
            local file, err = fs.open(filepath, "w")
            fs.close(file)
        end

        self:edit()
        self:terminate()
    end

    function file_editor:edit()
        while true do
            local character
            local output
            while character == nil do
                cursor:show()
                output = event:listen(0.5)
                if output ~= nil and type(output) == "string" then
                    character = output
                    break
                end
                cursor:hide()
                output = event:listen(0.5)
                if output ~= nil and type(output) == "string" then
                    character = output
                    break
                end
            end
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
                self.editor_buffer:saveToFile(self.filepath)
            elseif character == "w" and keyboard:getCtrl() then
                break
            elseif #character == 1 then
                self.editor_buffer:insertCharacter(character)
            end
            local x_pos, y_pos = self.editor_buffer:getCursorPosition()
            cursor:setPosition(x_pos, y_pos)
        end
    end

return file_editor
