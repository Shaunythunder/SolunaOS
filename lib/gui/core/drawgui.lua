-- /lib/gui/draw_gui.lua

local draw = require("draw")
local colors = require("colors")
local unicode = require("unicode")

local drawgui = {}

    function drawgui.renderBackground(mode, bg_color, image_path)
        local gpu = _G.primary_gpu
        local height = _G.height
        local width = _G.width
        bg_color = bg_color or colors.BLACK
        if mode == "fill" then
            gpu.setBackground(bg_color)
            gpu.fill(1, 1, width, height, " ")
            return
        elseif mode == "image" then
            if not image_path then
                error("No valid image path")
            end
            draw.image(image_path, 1, 1)
            return
        end
    end

    function drawgui.renderTaskbar()
        local gpu = _G.primary_gpu
        local width = _G.width
        local height = _G.height
        local taskbar_height = 2
        local taskbar_color = colors.DARKGRAY
        gpu.setBackground(taskbar_color)
        gpu.fill(1, height - taskbar_height + 1, width, taskbar_height, " ")
    end

    function drawgui.renderWindow(window_obj)
        local gpu = _G.primary_gpu
        local bg_color = window_obj.bg or colors.DARKGRAY
        local border_color = window_obj.border or colors.LIGHTGRAY

        local end_x = window_obj.x + window_obj.width - 1
        local end_y = window_obj.y + window_obj.height - 1

        gpu.setBackground(bg_color)
        gpu.fill(window_obj.x + 1, window_obj.y + 1, window_obj.width - 2, window_obj.height - 2, " ")

        gpu.setBackground(border_color)
        draw.horzLine(window_obj.x, window_obj.y, window_obj.width, 1)
        draw.horzLine(window_obj.x, end_y, window_obj.width, 1)
        draw.vertLine(window_obj.x, window_obj.y, window_obj.height, 1)
        draw.vertLine(end_x, window_obj.y, window_obj.height, 1)

        if window_obj.title then
            gpu.setForeground(colors.BLACK)
            gpu.set(window_obj.x + 1, window_obj.y, window_obj.title)
        end

        local close_symbol = window_obj.close_button_symbol or unicode.CLOSE
        local max_symbol = window_obj.max_button_symbol or unicode.MAXIMIZE
        local min_symbol = window_obj.min_button_symbol or unicode.MINIMIZE

        local button_rack_y = window_obj.y
        local close_pos = window_obj.close_button_x or (end_x - 1)
        local max_pos = window_obj.max_button_x or (close_pos - 2)
        local min_pos = window_obj.min_button_x or (max_pos - 2)

        local close_color = window_obj.close_button_color or colors.DARKGRAY
        local max_color = window_obj.max_button_color or colors.DARKGRAY
        local min_color = window_obj.min_button_color or colors.DARKGRAY

        draw.singleCharacter(close_symbol, close_pos, button_rack_y, colors.BLACK, close_color)
        draw.singleCharacter(max_symbol, max_pos, button_rack_y, colors.BLACK, max_color)
        draw.singleCharacter(min_symbol, min_pos, button_rack_y, colors.BLACK, min_color)
    end

    function drawgui.renderDivider(y_pos, color)
        local gpu = _G.primary_gpu
        local width = _G.width
        color = color or colors.DARKGRAY
        gpu.setBackground(color)
        gpu.fill(1, y_pos, width, 1, " ")
    end

    function drawgui.renderText(x, y, text, fg_color, bg_color)
        local gpu = _G.primary_gpu
        if fg_color then
            gpu.setForeground(fg_color)
        end
        if bg_color then
            gpu.setBackground(bg_color)
        end
        gpu.set(x, y, text)
    end

    function drawgui.renderButton(x_pos, y_pos, width, height, bg_color, border_color, text)
    local gpu = _G.primary_gpu
        bg_color = bg_color or colors.PURPLE
        border_color = border_color or colors.OFF_WHITE
        gpu.setBackground(bg_color)
        gpu.fill(x_pos + 1, y_pos + 1, width - 2, height - 2, " ")
        gpu.setBackground(border_color)
        gpu.fill(x_pos, y_pos, width, 1, " ")
        gpu.fill(x_pos, y_pos + height - 1, width, 1, " ")
        gpu.fill(x_pos, y_pos, 1, height, " ")
        gpu.fill(x_pos + width - 1, y_pos, 1, height, " ")
        if text then
            gpu.setForeground(0xFFFFFF)
            local text_x = x_pos + math.floor((width - #text) / 2)
            gpu.set(text_x, y_pos + math.floor(height / 2), text)
        end
end


return drawgui