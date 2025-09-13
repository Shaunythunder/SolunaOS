-- /lib/core/draw.lua

local gpu = _G.primary_gpu
local cursor = _G.cursor
local BLACK = 0x000000
local WHITE = 0xFFFFFF

local draw = {}

    --- Updates the resolution variables
    function draw.updateResolution()
        _G.width, _G.height = gpu.getResolution()
    end

    --- Clears the screen to black
    function draw.clear()
        local h = _G.height
        local w = _G.width
        gpu.setForeground(WHITE)
        gpu.setBackground(BLACK)
        gpu.fill(1, 1, w, h, " ")
    end

    --- Renders a string at specified coordinates at the specified color
    --- @param x_pos number
    --- @param y_pos number
    --- @param color number Color value (0xRRGGBB)
    --- @return string|nil error
    function draw.pixel(x_pos, y_pos, color)
        local h = _G.height
        local w = _G.width
        if x_pos < 1 or x_pos > w or y_pos < 1 or y_pos > h then
            return "Position out of bounds"
        end
        gpu.setForeground(color)
        gpu.setBackground(color)
        gpu.fill(x_pos, y_pos, 1, 1, " ")
    end

    function draw.dualPixel(x_pos, y_pos, top_color, bottom_color)
        local h = _G.height
        local w = _G.width
        if x_pos < 1 or x_pos > w or y_pos < 1 or y_pos > h then
            return "Position out of bounds"
        end
        gpu.setForeground(top_color)
        gpu.setBackground(bottom_color)
        gpu.set(x_pos, y_pos, "▀")
    end

    --- Renders an image from a table of pixels.
    --- Table format: { {x, y, top_color, bottom_color}, ... }
    --- Images must be accessible from package path in 00_boot.lua
    --- Use image_to_pixel.py to convert images to pixel tables.
    --- @param image_path string Name of the image module (without .lua)
    --- @param x_pos number|nil X position (optional, defaults to 1)
    --- @param y_pos number|nil Y position (optional, defaults to 1)
    --- @return string|nil error
    function draw.image(image_path, x_pos, y_pos)
        local image = require(image_path)
        local x_pos = x_pos or 1
        local y_pos = y_pos or 1
        for _, pixel in ipairs(image) do
            draw.dualPixel(pixel[1] + x_pos - 1, pixel[2] + y_pos - 1, pixel[3], pixel[4])
        end
    end

    -- Gets the RGB color value from R, G, B components
    --- @param r number Red component (0-255)
    --- @param g number  Green component (0-255)
    --- @param b number Blue component (0-255)
    --- @return number Color value (0xRRGGBB)
    function draw.rgbToHex(r, g, b)
        if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then
            error("RGB values must be numbers")
        end
        if r < 0 or r > 255 or g < 0 or g > 255 or b < 0 or b > 255 then
            error("RGB values must be between 0 and 255")
        end
        local color = (r << 16) | (g << 8) | b
        return color
    end

    -- Renders a single character at specified coordinates at the specified color
    --- @param char string
    --- @param x_pos number|nil X position (optional, defaults to cursor X)
    --- @param y_pos number|nil Y position (optional, defaults to cursor home Y)
    --- @param foreground number|nil (0xRRGGBB, optional, defaults to white)
    --- @param background number|nil (0xRRGGBB, optional, defaults to black)
    --- @return string|nil error
    function draw.singleCharacter(char, x_pos, y_pos, foreground, background)
        local h = _G.height
        local x_home = x_pos or cursor:getX()
        local home_y = y_pos or cursor:getHomeY()
        local fg = foreground or WHITE
        local bg = background or BLACK
        gpu.setForeground(fg)
        gpu.setBackground(bg)
        if home_y > h then
            return "Y position out of bounds"
        end
        gpu.set(x_home, home_y, char)
    end

    function draw.singleLineText(raw_line, x_pos, y_pos, foreground, background)
        local h = _G.height
        local w = _G.width
        local x_home = x_pos or cursor:getX()
        local home_y = y_pos or cursor:getHomeY()
        local fg = foreground or WHITE
        local bg = background or BLACK
        gpu.setForeground(fg)
        gpu.setBackground(bg)
        if home_y > h then
            return "Y position out of bounds"
        end
        gpu.fill(1, home_y, w, 1, " ")
        gpu.set(x_home, home_y, raw_line:sub(1, w))
    end

    function draw.highlightText(string, x_pos, y_pos, foreground, background)
        local fg = foreground or BLACK
        local bg = background or WHITE
        gpu.setForeground(fg)
        gpu.setBackground(bg)
        gpu.fill(x_pos, y_pos, #string, 1, " ")
        gpu.set(x_pos, y_pos, string)
    end

    -- Renders text for terminal, line by line
    ---@param raw_line string
    ---@param x_pos number|nil
    ---@param y_pos number|nil
    ---@param foreground number|nil hex only, use render.getRGB() white default
    ---@param background number|nil hex only, use render.getRGB() black default
    function draw.termText(raw_line, x_pos, y_pos, foreground, background)
        local h = _G.height
        local w = _G.width
        local active_scroll_buffer = _G.scroll_buffer
        local x_home = x_pos or cursor:getX()
        local home_y = y_pos or cursor:getHomeY()
        local fg = foreground or WHITE
        local bg = background or BLACK
        gpu.setForeground(fg)
        gpu.setBackground(bg)
        local y_below = h - home_y - 1
        if y_below > 0 then
            gpu.fill(1, home_y + 1, w, y_below, " ")
        end

         local lines = {}
        for actual_line in raw_line:gmatch("([^\n]*)\n?") do
            table.insert(lines, actual_line)
        end

        local display_lines = {}
        for _, line in ipairs(lines) do
            while #line > 0 do
                if #line > _G.width then
                    local wrapped_line = line:sub(1, _G.width)
                    table.insert(display_lines, wrapped_line)
                    line = line:sub(_G.width + 1)
                else
                    table.insert(display_lines, line)
                    break
                end
            end
        end

        gpu.fill(1, home_y, w, #display_lines, " ")
        for _, line_text in ipairs(display_lines) do
            if home_y > h then
                if active_scroll_buffer then
                    active_scroll_buffer:pushUp()
                    home_y = home_y - 1
                    cursor:setHomeY(home_y)
                else
                    break
                end
            end
            gpu.set(x_home, home_y, line_text)
            home_y = home_y + 1
        end
    end

    --- Draws a box from start xy coordinates. Lineweight determines the thickness.
    --- @param start_x number
    --- @param start_y number
    --- @param end_x number
    --- @param end_y number
    --- @param color number hex only, use render.getRGB()
    --- @param lineweight number
    function draw.box(start_x, start_y, end_x, end_y, color, lineweight)
        lineweight = lineweight or 0
        gpu.setForeground(color)
        gpu.setBackground(color)
        if end_x < start_x or end_y < start_y then
            return "Invalid box coordinates"
        end
        local x_diff = end_x - start_x + 1
        local y_diff = end_y - start_y + 1
        local lineweight_x = lineweight
        local lineweight_y = lineweight
        if lineweight_x > x_diff then
            lineweight_x = x_diff
        end
        if lineweight_y > y_diff then
            lineweight_y = y_diff
        end
        if lineweight == 0 then
            gpu.fill(start_x, start_y, x_diff, y_diff, " ")
        else
        gpu.fill(start_x, start_y, x_diff, lineweight, " ")
        gpu.fill(start_x, end_y - lineweight + 1, x_diff, lineweight, " ")
        gpu.fill(start_x, start_y, lineweight, y_diff, " ")
        gpu.fill(end_x - lineweight + 1, start_y, lineweight, y_diff, " ")
        end
    end

    -- NOTE: WORKS BUT SEVERAL ISSUES, IT'S AN ELLIPSE AND WE CAN'T BE DRAWING PIXEL BY PIXEL.
    -- WHAT WE NEED TO DO IS TO EITHER CALCULATE AND CACHE THE DIFFERENT LINES AND THEN DRAW THEM,
    -- TO TURN 500 DRAWS INTO 10 OR... DON'T DRAW CIRCLES.
    function draw.circle(center_x, center_y, radius, color, lineweight)
        local height = _G.height
        local width = _G.width
        lineweight = lineweight or 0
        if center_x < 1 or center_x > width or center_y < 1 or center_y > height then
            return "Position out of bounds"
        end

        gpu.setForeground(color)
        gpu.setBackground(color)
        local radius_sq = radius * radius
        local min_rad_sq = (radius - lineweight) * (radius - lineweight)
        for x_pos = center_x - radius, center_x + radius do
            for y_pos = center_y - radius, center_y + radius do
                local diff_x = x_pos - center_x
                local diff_y = y_pos - center_y
                local distance_sq = diff_x * diff_x + diff_y * diff_y
                if lineweight == 0 then
                    if distance_sq <= radius_sq then
                        draw.pixel(x_pos, y_pos, color)
                    end
                elseif distance_sq >= min_rad_sq and distance_sq <= radius_sq then
                    draw.pixel(x_pos, y_pos, color)
                end
            end
        end
    end

    -- SAME DEAL AS CIRCLES, DRAFT VERSION UNTESTED
    function draw.ellipse(center_x, center_y, x_radius, y_radius, color, lineweight)
        local h = _G.height
        local w = _G.width
        lineweight = lineweight or 0
        if center_x < 1 or center_x > w or center_y < 1 or center_y > h then
            return "Position out of bounds"
        end

        gpu.setForeground(color)
        gpu.setBackground(color)

        local lineweight_ratio = lineweight / math.min(x_radius, y_radius)
        for x_pos = center_x - x_radius, center_x + x_radius do
            for y_pos = center_y - y_radius, center_y + y_radius do
                local norm_x = (x_pos - center_x) / x_radius
                local norm_y = (y_pos - center_y) / y_radius
                local distance_sq = norm_x * norm_x + norm_y * norm_y
                if lineweight == 0 then
                    if distance_sq <= 1 then
                        draw.pixel(x_pos, y_pos, color)
                    end
                elseif distance_sq >= 1 - lineweight_ratio and distance_sq <= 1 then
                    draw.pixel(x_pos, y_pos, color)
                end
            end
        end
    end

    -- UNTESTED, NEED TO ADD LINEWIEGHT FUNCTIONALITY
    function draw.triangle(x_pos_1, x_pos_2, x_pos_3, y_pos_1, y_pos_2, y_pos_3, color)
        draw.freeLine(x_pos_1, y_pos_1, x_pos_2, y_pos_2, color)
        draw.freeLine(x_pos_2, y_pos_2, x_pos_3, y_pos_3, color)
        draw.freeLine(x_pos_3, y_pos_3, x_pos_1, y_pos_1, color)
    end

    -- Draws a horizontal line from start_x to end_x from y_pos
    ---@param start_x number
    ---@param start_y number
    ---@param length number
    ---@param thickness number|nil defaults to 1
    ---@param color number|nil hex only, use render.getRGB()
    function draw.horzLine(start_x, start_y, length, thickness, color)
        local thickness = thickness or 1
        if color then
            gpu.setForeground(color)
        end
        gpu.fill(start_x, start_y, length, thickness, " ")
    end

    --- Draws a vertical line from start_y to end_y from x_pos
    --- @param start_x number
    --- @param start_y number
    --- @param height number
    --- @param thickness number|nil defaults to 1
    --- @param color number|nil hex only, use render.getRGB()
    function draw.vertLine(start_x, start_y, height, thickness, color)
        local thickness = thickness or 1
        if color then
            gpu.setBackground(color)
        end
        gpu.fill(start_x, start_y, thickness, height, " ")
    end

    --- Draws a free line from start to end coordinates
    --- @param start_x number
    --- @param start_y number
    --- @param end_x number
    --- @param end_y number
    --- @param color number hex only, use render.getRGB()
    function draw.freeLine(start_x, start_y, end_x, end_y, color)
        local diff_x = math.abs(end_x - start_x)
        local diff_y = math.abs(end_y - start_y)

        local step_x
        if start_x < end_x then
            step_x = 1
        else
            step_x = -1
        end

        local step_y
        if start_y < end_y then
            step_y = 1
        else
            step_y = -1
        end

        local err = diff_x - diff_y
        local x_pos = start_x
        local y_pos = start_y
        while true do
            draw.pixel(x_pos, y_pos, color)
            if x_pos == end_x and y_pos == end_y then
                break
            end
            local double_err = err * 2
            if double_err > -diff_y then
                err = err - diff_y
                x_pos = x_pos + step_x
            end
            if double_err < diff_x then
                err = err + diff_x
                y_pos = y_pos + step_y
            end
        end
    end

return draw