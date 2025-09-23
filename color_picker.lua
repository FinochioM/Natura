local color_picker = {}

local picker_state = {
    active = false,
    mode = "hsv", -- "hsv", "rgb"  
    hsl = {0, 1, 0.5}, -- hue, saturation, lightness
    rgba = {1, 0, 0, 1}, -- red, green, blue, alpha
    point = {0, 0}, -- x,y position in 2D picker area
    value = 0, -- slider value
    rect = {x = 0, y = 0, w = 200, h = 200},
    mouse_down = false,
    active_area = nil -- "main", "slider", "alpha"
}

function color_picker.hsl_to_rgb(h, s, l)
    local r, g, b
    
    if s == 0 then
        r, g, b = l, l, l
    else
        local function hue_to_rgb(p, q, t)
            if t < 0 then t = t + 1 end
            if t > 1 then t = t - 1 end
            if t < 1/6 then return p + (q - p) * 6 * t end
            if t < 1/2 then return q end
            if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
            return p
        end
        
        local q = l < 0.5 and l * (1 + s) or l + s - l * s
        local p = 2 * l - q
        
        r = hue_to_rgb(p, q, h + 1/3)
        g = hue_to_rgb(p, q, h)
        b = hue_to_rgb(p, q, h - 1/3)
    end
    
    return r, g, b
end

function color_picker.rgb_to_hsl(r, g, b)
    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local h, s, l = 0, 0, (max + min) / 2

    if max == min then
        h, s = 0, 0
    else
        local d = max - min
        s = l > 0.5 and d / (2 - max - min) or d / (max + min)
        
        if max == r then
            h = (g - b) / d + (g < b and 6 or 0)
        elseif max == g then
            h = (b - r) / d + 2
        else
            h = (r - g) / d + 4
        end
        h = h / 6
    end

    return h, s, l
end

function color_picker.color_to_hex(r, g, b, a)
    r = math.floor(r * 255 + 0.5)
    g = math.floor(g * 255 + 0.5)
    b = math.floor(b * 255 + 0.5)
    a = math.floor((a or 1) * 255 + 0.5)
    return string.format("%02X%02X%02X%02X", r, g, b, a)
end

function color_picker.hex_to_color(hex)
    hex = hex:gsub("#", "")
    if #hex == 6 then hex = hex .. "FF" end
    if #hex ~= 8 then return 1, 0, 0, 1 end
    
    local r = tonumber(hex:sub(1, 2), 16) / 255
    local g = tonumber(hex:sub(3, 4), 16) / 255
    local b = tonumber(hex:sub(5, 6), 16) / 255
    local a = tonumber(hex:sub(7, 8), 16) / 255
    
    return r, g, b, a
end

function color_picker.set_color(r, g, b, a)
    picker_state.rgba = {r, g, b, a or 1}
    local h, s, l = color_picker.rgb_to_hsl(r, g, b)
    picker_state.hsl = {h, s, l}
    
    if picker_state.mode == "hsv" then
        picker_state.value = h
        picker_state.point = {s, 1 - l}
    end
end

function color_picker.update_from_point(x, y, finalize)
    local rect = picker_state.rect
    local rel_x = math.max(0, math.min(1, (x - rect.x) / rect.w))
    local rel_y = math.max(0, math.min(1, (y - rect.y) / rect.h))
    
    picker_state.point = {rel_x, rel_y}
    
    if picker_state.mode == "hsv" then
        local h = picker_state.value
        local s = rel_x
        local l = 1 - rel_y
        
        picker_state.hsl = {h, s, l}
        local r, g, b = color_picker.hsl_to_rgb(h, s, l)
        picker_state.rgba = {r, g, b, picker_state.rgba[4]}
    end
    
    if finalize then
        color_picker.on_color_change()
    end
end

function color_picker.update_from_slider(x, y, finalize)
    local slider_rect = {
        x = picker_state.rect.x + picker_state.rect.w + 10,
        y = picker_state.rect.y,
        w = 20,
        h = picker_state.rect.h
    }
    
    local rel_y = math.max(0, math.min(1, (y - slider_rect.y) / slider_rect.h))
    picker_state.value = rel_y
    
    if picker_state.mode == "hsv" then
        local h = rel_y
        local s = picker_state.point[1]
        local l = 1 - picker_state.point[2]
        
        picker_state.hsl = {h, s, l}
        local r, g, b = color_picker.hsl_to_rgb(h, s, l)
        picker_state.rgba = {r, g, b, picker_state.rgba[4]}
    end
    
    if finalize then
        color_picker.on_color_change()
    end
end

function color_picker.on_color_change()
    -- called by color_preview when a color changes
    -- implement the actual color updating later
end

function color_picker.show(x, y, initial_color)
    picker_state.active = true
    picker_state.rect = {x = x, y = y, w = 200, h = 200}
    
    if initial_color then
        local r, g, b, a = color_picker.hex_to_color(initial_color)
        color_picker.set_color(r, g, b, a)
    end
end

function color_picker.hide()
    picker_state.active = false
    picker_state.mouse_down = false
    picker_state.active_area = nil
end

function color_picker.handle_mouse_pressed(x, y, button)
    if not picker_state.active then return false end
    
    local rect = picker_state.rect
    local slider_rect = {
        x = rect.x + rect.w + 10,
        y = rect.y,
        w = 20,
        h = rect.h
    }
    
    if button == 1 then
        if x >= rect.x and x <= rect.x + rect.w and 
           y >= rect.y and y <= rect.y + rect.h then
            picker_state.mouse_down = true
            picker_state.active_area = "main"
            color_picker.update_from_point(x, y, true)
            return true
        end
        
        if x >= slider_rect.x and x <= slider_rect.x + slider_rect.w and
           y >= slider_rect.y and y <= slider_rect.y + slider_rect.h then
            picker_state.mouse_down = true
            picker_state.active_area = "slider"
            color_picker.update_from_slider(x, y, true)
            return true
        end
    end
    
    return false
end

function color_picker.handle_mouse_moved(x, y)
    if not picker_state.active or not picker_state.mouse_down then return end
    
    if picker_state.active_area == "main" then
        color_picker.update_from_point(x, y, false)
    elseif picker_state.active_area == "slider" then
        color_picker.update_from_slider(x, y, false)
    end
end

function color_picker.handle_mouse_released(x, y, button)
    if not picker_state.active then return false end
    
    if button == 1 and picker_state.mouse_down then
        if picker_state.active_area == "main" then
            color_picker.update_from_point(x, y, true)
        elseif picker_state.active_area == "slider" then
            color_picker.update_from_slider(x, y, true)
        end
        
        picker_state.mouse_down = false
        picker_state.active_area = nil
        return true
    end
    
    return false
end

function color_picker.draw()
    if not picker_state.active then return end
    
    local colors = require("colors")
    local rect = picker_state.rect
    
    local steps = 50
    for i = 0, steps do
        for j = 0, steps do
            local s = i / steps
            local l = 1 - (j / steps)
            local h = picker_state.value
            
            local r, g, b = color_picker.hsl_to_rgb(h, s, l)
            love.graphics.setColor(r, g, b, 1)
            
            local px = rect.x + (i / steps) * rect.w
            local py = rect.y + (j / steps) * rect.h
            local pw = rect.w / steps + 1
            local ph = rect.h / steps + 1
            
            love.graphics.rectangle("fill", px, py, pw, ph)
        end
    end
    
    colors.set_color("ui_dim")
    love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h)
    
    local slider_rect = {
        x = rect.x + rect.w + 10,
        y = rect.y,
        w = 20,
        h = rect.h
    }
    
    for i = 0, 100 do
        local h = i / 100
        local r, g, b = color_picker.hsl_to_rgb(h, 1, 0.5)
        love.graphics.setColor(r, g, b, 1)
        
        local py = slider_rect.y + (i / 100) * slider_rect.h
        local ph = slider_rect.h / 100 + 1
        love.graphics.rectangle("fill", slider_rect.x, py, slider_rect.w, ph)
    end
    
    colors.set_color("ui_dim")
    love.graphics.rectangle("line", slider_rect.x, slider_rect.y, slider_rect.w, slider_rect.h)
    
    colors.set_color("text")
    
    local point_x = rect.x + picker_state.point[1] * rect.w
    local point_y = rect.y + picker_state.point[2] * rect.h
    love.graphics.circle("line", point_x, point_y, 8)
    
    local slider_y = slider_rect.y + picker_state.value * slider_rect.h
    love.graphics.rectangle("line", slider_rect.x - 2, slider_y - 2, slider_rect.w + 4, 4)
    
    local preview_rect = {
        x = slider_rect.x + slider_rect.w + 10,
        y = rect.y,
        w = 40,
        h = 40
    }
    
    love.graphics.setColor(picker_state.rgba[1], picker_state.rgba[2], picker_state.rgba[3], picker_state.rgba[4])
    love.graphics.rectangle("fill", preview_rect.x, preview_rect.y, preview_rect.w, preview_rect.h)
    
    colors.set_color("ui_dim")
    love.graphics.rectangle("line", preview_rect.x, preview_rect.y, preview_rect.w, preview_rect.h)
    
    colors.set_color("text")
    local hex = color_picker.color_to_hex(picker_state.rgba[1], picker_state.rgba[2], picker_state.rgba[3], picker_state.rgba[4])
    love.graphics.print("#" .. hex, preview_rect.x, preview_rect.y + preview_rect.h + 5)
end

function color_picker.get_current_color()
    return picker_state.rgba[1], picker_state.rgba[2], picker_state.rgba[3], picker_state.rgba[4]
end

function color_picker.get_current_hex()
    return color_picker.color_to_hex(picker_state.rgba[1], picker_state.rgba[2], picker_state.rgba[3], picker_state.rgba[4])
end

function color_picker.is_active()
    return picker_state.active
end

return color_picker