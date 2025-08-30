-- /lib/environments/file_editor.lua
local fs = require("filesystem")
local shell = require("shell")
local draw = require("draw")
local text_buffer = require("text_buffer")
local event = require("event")
local keyboard = _G.keyboard
local cursor = _G.cursor

local file_editor = {}
    file_editor.__index = file_editor

    function file_editor.new()
        local self = setmetatable({}, file_editor)
        self.file_path = ""
        self.file_content = ""
        self.file_pos = 1
        return self
    end

    function file_editor:terminate()
        for attribute in pairs(self) do
            self[attribute] = nil -- Clear methods to free up memory
        end
        setmetatable(self, nil)
    end

    function file_editor:run(filepath)
        draw.clear()
        local exists = fs.exists(filepath)
        local file
        if exists then
            file = fs.open(filepath, "r")
            self.file_content = fs.read(file) or ""
            fs.close(file)
        else
            file = fs.open(filepath, "w")
            fs.close(file)
            self.file_content = ""
        end
        self:edit()
        file = fs.open(filepath, "w")
        fs.write(file, self.file_content)
        fs.close(file)
        self:terminate()
    end

    function file_editor:edit()
        local height = _G.height
        local width = _G.width
        local input_buffer = text_buffer.new()
        input_buffer:setText(self.file_content)
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
                input_buffer:insert("\n")
            elseif character == "\t" then
                input_buffer:insert("    ")
            elseif character == "\b" then
                input_buffer:backspace()
            elseif character == "del" then
                input_buffer:delete()
            elseif character == "<-" then
                input_buffer:moveLeft()
            elseif character == "->" then
                input_buffer:moveRight()
            elseif character == "\\^" then
                input_buffer:moveUp()
            elseif character == "\\v" then
                input_buffer:moveDown()
            elseif character == "s" and keyboard:getCtrl() then
                self.file_content = input_buffer:getText()
            elseif character == "w" and keyboard:getCtrl() then
                break
            elseif #character == 1 then
                input_buffer:insert(character)
            end
            local string = input_buffer:getText()
            draw.termText(string, 1)
            local cursor_x = (input_buffer:getPosition()) % (width)
            local cursor_y = cursor:getHomeY() + math.floor((input_buffer:getPosition() - 1) / width)
            cursor:setPosition(cursor_x, cursor_y)
        end
    end

return file_editor
