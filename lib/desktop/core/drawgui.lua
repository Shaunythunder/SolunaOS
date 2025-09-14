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

    function drawgui.renderTaskbar(taskbar)
        local bg_color = taskbar.bg_color or colors.DARKGRAY
        if taskbar.image then
            draw.image(taskbar.image, taskbar.x_pos, taskbar.y_pos)
            return
        end
        local gpu = _G.primary_gpu
        local taskbar_height = 3
        local taskbar_color = bg_color or colors.DARKGRAY
        gpu.setBackground(taskbar_color)
        gpu.fill(taskbar.x_pos, taskbar.y_pos, taskbar.width, taskbar_height, " ")
    end

    function drawgui.renderRamMeter(ram_meter)
        local gpu = _G.primary_gpu
        local x_pos = ram_meter.x_pos
        local y_pos = ram_meter.y_pos
        local meter_width = ram_meter.width
        local meter_height = ram_meter.height
        local ram_used = ram_meter.used_ram
        local ram_total = ram_meter.total_ram
        local used_fraction = ram_used / ram_total
        local used_percentage = used_fraction * 100


        local used_width = meter_width * used_fraction
        local free_width = meter_width - used_width


        local function percentToRGBHex(percent)
            local r = math.floor(255 * (percent / 100))
            local g = math.floor(255 * (1 - percent / 100))
            local b = 0
            return draw.rgbToHex(r, g, b)
        end

        local used_color = percentToRGBHex(used_percentage)
        local free_color = colors.BLACK

        draw.singleLineText(ram_meter.text, x_pos, y_pos + 1, colors.BLACK, ram_meter.taskbar_color)

        gpu.setBackground(used_color)
        gpu.fill(x_pos, y_pos, used_width, meter_height, " ")

        gpu.setBackground(free_color)
        gpu.fill(x_pos + used_width, y_pos, free_width, meter_height, " ")

        local text = string.format("%d%%", math.floor(used_percentage))
        local text_x = x_pos + math.floor((meter_width - #text) / 2)
        local text_y = y_pos + math.floor(meter_height / 2)
        gpu.setForeground(colors.WHITE)

        for i = 1, #text do
            local char_x = text_x + i - 1
            if char_x < x_pos + used_width - 1 then
                gpu.setBackground(used_color)
            else
                gpu.setBackground(free_color)
            end
            gpu.setForeground(colors.WHITE)
            gpu.set(char_x, text_y, text:sub(i, i))
        end
    end

    function drawgui.renderIcon(icon)
        local image = icon.image
        local x_pos = icon.x_pos
        local y_pos = icon.y_pos
        local width = icon.width
        local height = icon.height
        local label = icon.label
        local label_x_pos = x_pos
        local label_y_pos = y_pos + height

        if icon.image then
            draw.image(image, x_pos, y_pos)
            draw.wrappedText(label, width, label_x_pos, label_y_pos, colors.BLACK)
            return
        end

        local bg_color = icon.color
        draw.box(x_pos, y_pos, x_pos + width - 1, y_pos + height - 1, bg_color, 0)
        draw.wrappedText(label, width, label_x_pos, label_y_pos, colors.BLACK)
    end

    function drawgui.renderStartButton(start_button)
        local clicked_image = start_button.image_clicked
        local not_clicked_image = start_button.image_unclicked
        local x_pos = start_button.x_pos
        local y_pos = start_button.y_pos
        local width = start_button.width
        local height = start_button.height

        if clicked_image and not_clicked_image then
            if start_button.clicked then
                draw.image(clicked_image, x_pos, y_pos)
            else
                draw.image(not_clicked_image, x_pos, y_pos)
            end
            return
        else
            local gpu = _G.primary_gpu
            local button_color = colors.BLUE
            gpu.setBackground(button_color)
            gpu.fill(x_pos, y_pos, width, height, " ")
        end
    end

    function drawgui.renderTaskbarMenu(taskbar_menu)
        local gpu = _G.primary_gpu
        local x_pos = taskbar_menu.x_pos
        local y_pos = taskbar_menu.y_pos
        local width = taskbar_menu.width
        local height = taskbar_menu.height
        local bg_color = taskbar_menu.bg_color or colors.LIGHTGRAY
        local text_color = taskbar_menu.text_color or colors.BLACK


        gpu.setBackground(bg_color)
        gpu.fill(x_pos, y_pos, width, height, " ")

        gpu.setForeground(text_color)
        local renderable_items = {}
        for _, item in ipairs(taskbar_menu.items) do
            if item.name and item.action then
                table.insert(renderable_items, item)
            end
        end
        for _, item in ipairs(renderable_items) do
            local item_y = item.y_pos
            local item_text = item.name
            if #item_text > width - 2 then
                item_text = item_text:sub(1, width - 5) .. "..."
            end
            gpu.set(x_pos + 1, item_y, item_text)
        end
    end

    function drawgui.renderWindow(window_obj)
        local gpu = _G.primary_gpu
        local bg_color = window_obj.bg or colors.DARKGRAY
        local border_color = window_obj.border or colors.LIGHTGRAY

        local end_x = window_obj.x_pos + window_obj.width - 1
        local end_y = window_obj.y_pos + window_obj.height - 1

        gpu.setBackground(bg_color)
        gpu.fill(window_obj.x_pos + 1, window_obj.y_pos + 1, window_obj.width - 2, window_obj.height - 2, " ")

        gpu.setBackground(border_color)
        draw.horzLine(window_obj.x_pos, window_obj.y_pos, window_obj.width, 1)
        draw.horzLine(window_obj.x_pos, end_y, window_obj.width, 1)
        draw.vertLine(window_obj.x_pos, window_obj.y_pos, window_obj.height, 1)
        draw.vertLine(end_x, window_obj.y_pos, window_obj.height, 1)

        if window_obj.title then
            gpu.setForeground(colors.BLACK)
            gpu.set(window_obj.x_pos + 1, window_obj.y_pos, window_obj.title)
        end

        -- Close, Maximize, Minimize Buttons
        local close_symbol = window_obj.close_button_symbol or unicode.CLOSE
        local max_symbol = window_obj.max_button_symbol or unicode.MAXIMIZE
        local min_symbol = window_obj.min_button_symbol or unicode.MINIMIZE

        local button_rack_y = window_obj.y_pos
        local close_pos = window_obj.close_button_x or (end_x - 1)
        local max_pos = window_obj.max_button_x or (close_pos - 2)
        local min_pos = window_obj.min_button_x or (max_pos - 2)

        local close_color = window_obj.close_button_color or colors.DARKGRAY
        local max_color = window_obj.max_button_color or colors.DARKGRAY
        local min_color = window_obj.min_button_color or colors.DARKGRAY

        draw.singleCharacter(close_symbol, close_pos, button_rack_y, colors.BLACK, close_color)
        draw.singleCharacter(max_symbol, max_pos, button_rack_y, colors.BLACK, max_color)
        draw.singleCharacter(min_symbol, min_pos, button_rack_y, colors.BLACK, min_color)

        -- Window expansion buttons
        local expand_button_x = window_obj.expand_button_x
        local expand_button_y = window_obj.expand_button_y
        local expand_button_color = window_obj.expand_button_color
        local expand_button_symbol = window_obj.expand_button_symbol

        draw.singleCharacter(expand_button_symbol, expand_button_x, expand_button_y, colors.BLACK, expand_button_color)
    end

    function drawgui.renderEmergencyBorder()
        local gpu = _G.primary_gpu
        local width = _G.width
        local height = _G.height
        local warning_color = colors.RED

        gpu.setBackground(warning_color)
        draw.horzLine(1, 1, width, 1)
        draw.horzLine(1, height, width, 1)
        draw.vertLine(1, 1, height, 1)
        draw.vertLine(width, 1, height, 1)
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