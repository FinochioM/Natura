local scrollbar = {}
local colors = require("colors")

local scrollbar_fade_animations = {}
local scrollbar_active = false
local scrollbar_grab_offset = 0

function scrollbar.draw(editor_state, buffer, content_area)
    local config = require("config")
    
    if not config.get("show_scrollbar_marks") then
        return
    end
    
    local width_scale = config.get("scrollbar_width_scale") or 1.0
    if width_scale <= 0 then
        return
    end
    
    local font = love.graphics.getFont()
    local line_height = font:getHeight()
    local total_content_height = #buffer.lines * line_height
    local visible_height = content_area.h
    
    if total_content_height <= visible_height then
        return
    end
    
    local scrollbar_width = math.max(8 * width_scale, 4)
    local scrollbar_area = {
        x = content_area.x + content_area.w - scrollbar_width,
        y = content_area.y,
        w = scrollbar_width,
        h = content_area.h
    }
    
    local thumb_height = math.max((visible_height / total_content_height) * scrollbar_area.h, 20)
    local visible_lines = math.floor(visible_height / line_height)
    local max_scroll_lines = math.max(0, #buffer.lines - visible_lines)
    local current_scroll_lines = math.max(0, editor_state.viewport.top_line - 1)
    
    local scroll_percentage = 0
    if max_scroll_lines > 0 then
        scroll_percentage = current_scroll_lines / max_scroll_lines
    end
    
    local thumb_y = scrollbar_area.y + (scrollbar_area.h - thumb_height) * scroll_percentage
    
    local thumb_rect = {
        x = scrollbar_area.x + 2,
        y = thumb_y,
        w = scrollbar_area.w - 4,
        h = thumb_height
    }
    
    local opacity = scrollbar.calculate_opacity(scrollbar_area, "main_scrollbar")
    
    if opacity > 0 then
        colors.set_color("ui_dim")
        love.graphics.setColor(colors.get("ui_dim")[1], colors.get("ui_dim")[2], colors.get("ui_dim")[3], opacity * 0.3)
        love.graphics.rectangle("fill", scrollbar_area.x, scrollbar_area.y, scrollbar_area.w, scrollbar_area.h)
        
        colors.set_color("ui_default")
        love.graphics.setColor(colors.get("ui_default")[1], colors.get("ui_default")[2], colors.get("ui_default")[3], opacity)
        love.graphics.rectangle("fill", thumb_rect.x, thumb_rect.y, thumb_rect.w, thumb_rect.h, 2, 2)
    end
    
    return scrollbar_area, thumb_rect
end

function scrollbar.calculate_opacity(scrollbar_area, scrollbar_id)
    local config = require("config")
    local min_opacity = config.get("scrollbar_min_opacity") or 0.0
    local max_opacity = config.get("scrollbar_max_opacity") or 1.0
    local fade_sensitivity = config.get("scrollbar_fade_in_sensitivity") or 10.0
    
    local fadeout_opacity = min_opacity
    if scrollbar_fade_animations[scrollbar_id] then
        local anim = scrollbar_fade_animations[scrollbar_id]
        local elapsed = love.timer.getTime() - anim.start_time
        local delay = config.get("scrollbar_fade_out_delay_seconds") or 2.0
        
        if elapsed < delay then
            fadeout_opacity = max_opacity
        else
            local fade_duration = 0.5
            local fade_progress = math.min((elapsed - delay) / fade_duration, 1.0)
            fadeout_opacity = max_opacity * (1.0 - fade_progress)
            
            if fadeout_opacity <= min_opacity then
                scrollbar_fade_animations[scrollbar_id] = nil
                fadeout_opacity = min_opacity
            end
        end
    end
    
    local mouse_x, mouse_y = love.mouse.getPosition()
    local distance_to_scrollbar = math.max(math.abs(mouse_x - (scrollbar_area.x + scrollbar_area.w / 2)) - scrollbar_area.w / 2, 0)
    local font = love.graphics.getFont()
    local char_width = font:getWidth("M")
    local fade_threshold = char_width * fade_sensitivity
    local proximity_factor = math.max(0, 1.0 - (distance_to_scrollbar / fade_threshold))
    local proximity_opacity = min_opacity + (max_opacity - min_opacity) * proximity_factor
    
    return math.max(fadeout_opacity, proximity_opacity)
end

function scrollbar.start_fade_out_animation(scrollbar_id)
    scrollbar_fade_animations[scrollbar_id] = {
        start_time = love.timer.getTime()
    }
end

function scrollbar.handle_scroll(editor_state, buffer)
    scrollbar.start_fade_out_animation("main_scrollbar")
end

function scrollbar.handle_mouse_pressed(x, y, button, editor_state, buffer, content_area)
    if button ~= 1 then return false end
    
    local config = require("config")
    if not config.get("show_scrollbar_marks") then
        return false
    end
    
    local width_scale = config.get("scrollbar_width_scale") or 1.0
    if width_scale <= 0 then
        return false
    end
    
    local font = love.graphics.getFont()
    local line_height = font:getHeight()
    local total_content_height = #buffer.lines * line_height
    local visible_height = content_area.h
    
    if total_content_height <= visible_height then
        return false
    end
    
    local scrollbar_width = math.max(8 * width_scale, 4)
    local scrollbar_area = {
        x = content_area.x + content_area.w - scrollbar_width,
        y = content_area.y,
        w = scrollbar_width,
        h = content_area.h
    }
    
    if x < scrollbar_area.x or x > scrollbar_area.x + scrollbar_area.w or
       y < scrollbar_area.y or y > scrollbar_area.y + scrollbar_area.h then
        return false
    end
    
    local thumb_height = math.max((visible_height / total_content_height) * scrollbar_area.h, 20)
    local visible_lines = math.floor(visible_height / line_height)
    local max_scroll_lines = math.max(0, #buffer.lines - visible_lines)
    local current_scroll_lines = math.max(0, editor_state.viewport.top_line - 1)
    
    local scroll_percentage = 0
    if max_scroll_lines > 0 then
        scroll_percentage = current_scroll_lines / max_scroll_lines
    end
    
    local thumb_y = scrollbar_area.y + (scrollbar_area.h - thumb_height) * scroll_percentage
    
    if y >= thumb_y and y <= thumb_y + thumb_height then
        scrollbar_active = true
        scrollbar_grab_offset = y - thumb_y
        scrollbar.start_fade_out_animation("main_scrollbar")
        return true
    else
        local click_percentage = (y - scrollbar_area.y) / scrollbar_area.h
        local target_line = math.floor(click_percentage * max_scroll_lines) + 1
        target_line = math.max(1, math.min(target_line, #buffer.lines))
        
        editor_state.viewport.top_line = target_line
        editor_state.viewport.target_top_line = target_line
        
        scrollbar.start_fade_out_animation("main_scrollbar")
        return true
    end
end

function scrollbar.handle_mouse_moved(x, y, editor_state, buffer, content_area)
    if not scrollbar_active then return false end
    
    local config = require("config")
    if not config.get("show_scrollbar_marks") then
        return false
    end
    
    local font = love.graphics.getFont()
    local line_height = font:getHeight()
    local total_content_height = #buffer.lines * line_height
    local visible_height = content_area.h
    
    if total_content_height <= visible_height then
        return false
    end
    
    local scrollbar_width = math.max(8 * config.get("scrollbar_width_scale") or 1.0, 4)
    local scrollbar_area = {
        x = content_area.x + content_area.w - scrollbar_width,
        y = content_area.y,
        w = scrollbar_width,
        h = content_area.h
    }
    
    local thumb_height = math.max((visible_height / total_content_height) * scrollbar_area.h, 20)
    local visible_lines = math.floor(visible_height / line_height)
    local max_scroll_lines = math.max(0, #buffer.lines - visible_lines)
    
    local adjusted_y = y - scrollbar_grab_offset
    local scroll_percentage = (adjusted_y - scrollbar_area.y) / (scrollbar_area.h - thumb_height)
    scroll_percentage = math.max(0, math.min(1, scroll_percentage))
    
    local target_line = math.floor(scroll_percentage * max_scroll_lines) + 1
    target_line = math.max(1, math.min(target_line, #buffer.lines))
    
    editor_state.viewport.top_line = target_line
    editor_state.viewport.target_top_line = target_line
    
    return true
end

function scrollbar.handle_mouse_released(x, y, button)
    if button == 1 and scrollbar_active then
        scrollbar_active = false
        scrollbar_grab_offset = 0
        scrollbar.start_fade_out_animation("main_scrollbar")
        return true
    end
    return false
end

return scrollbar