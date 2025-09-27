local mouse = {}

local editor = require("editor")

local mouse_state = {
    pressed = false,
    press_start_x = 0,
    press_start_y = 0,
    press_start_time = 0,
    dragging = false,
    drag_threshold = 3,
    last_click_time = 0,
    last_click_line = 1,
    last_click_col = 0,
    last_click_count = 0,
    double_click_threshold = 0.4
}

function mouse.screen_to_editor_coords(x, y, ed)
    local content_start_y = 40
    local line_height = get_scaled_line_height()
    local text_start_x = get_text_start_x()
    
    if y < content_start_y then
        return nil, nil
    end
    
    local editor_area = get_editor_content_area()
    local gutter_width = get_line_number_gutter_width(current_buffer)
    
    if x < editor_area.x + gutter_width or x > editor_area.x + editor_area.width then
        return nil, nil
    end
    
    local line = ed.viewport.top_line + math.floor((y - content_start_y) / line_height)
    line = math.max(1, math.min(line, #current_buffer.lines))
    
    local font = love.graphics.getFont()
    local line_text = current_buffer.lines[line]
    local col = 0
    
    local target_x = x - text_start_x
    
    if target_x > 0 then
        for i = 1, #line_text do
            local char_width = font:getWidth(line_text:sub(i, i))
            if target_x <= char_width / 2 then
                col = i - 1
                break
            end
            target_x = target_x - char_width
            col = i
        end
    end
    
    return line, col
end

function mouse.clamp_to_buffer(line, col, buf)
    line = math.max(1, math.min(line, #buf.lines))
    col = math.max(0, math.min(col, #buf.lines[line]))
    return line, col
end

function mouse.select_word_at(ed, buf, line, col)
    local line_text = buf.lines[line]
    local start_col = col
    local end_col = col
    
    while start_col > 0 do
        local char = line_text:sub(start_col, start_col)
        if not char:match("[%w_]") then
            break
        end
        start_col = start_col - 1
    end
    
    while end_col < #line_text do
        local char = line_text:sub(end_col + 1, end_col + 1)
        if not char:match("[%w_]") then
            break
        end
        end_col = end_col + 1
    end
    
    ed.selection.active = true
    ed.selection.start_line = line
    ed.selection.start_col = start_col
    ed.selection.end_line = line
    ed.selection.end_col = end_col
    
    ed.cursor_line = line
    ed.cursor_col = end_col
end

function mouse.select_line_at(ed, buf, line)
    ed.selection.active = true
    ed.selection.start_line = line
    ed.selection.start_col = 0
    ed.selection.end_line = line
    ed.selection.end_col = #buf.lines[line]
    
    ed.cursor_line = line
    ed.cursor_col = #buf.lines[line]
end

function mouse.start_drag_selection(ed, buf, x, y)
    local line, col = mouse.screen_to_editor_coords(x, y, ed)
    if not line or not col then return false end
    
    line, col = mouse.clamp_to_buffer(line, col, buf)
    
    ed.selection.active = true
    ed.selection.start_line = line
    ed.selection.start_col = col
    ed.selection.end_line = line
    ed.selection.end_col = col
    
    ed.cursor_line = line
    ed.cursor_col = col
    
    editor.update_viewport(ed, buf)
    mouse_state.dragging = true
    return true
end

function mouse.update_drag_selection(ed, buf, x, y)
    if not mouse_state.dragging then return false end
    
    local line, col = mouse.screen_to_editor_coords(x, y, ed)
    if not line or not col then return false end
    
    line, col = mouse.clamp_to_buffer(line, col, buf)
    
    ed.selection.end_line = line
    ed.selection.end_col = col
    ed.cursor_line = line
    ed.cursor_col = col
    
    editor.update_viewport(ed, buf)
    return true
end

function mouse.handle_press(ed, buf, x, y, button)
    if button == 1 and y >= 40 then
        mouse_state.pressed = true
        mouse_state.press_start_x = x
        mouse_state.press_start_y = y
        mouse_state.press_start_time = love.timer.getTime()
        mouse_state.dragging = false
        return true
    end
    return false
end

function mouse.handle_drag(ed, buf, x, y, dx, dy)
    if not mouse_state.pressed then return false end
    
    local distance = math.sqrt((x - mouse_state.press_start_x)^2 + (y - mouse_state.press_start_y)^2)
    
    if not mouse_state.dragging and distance > mouse_state.drag_threshold then
        mouse.start_drag_selection(ed, buf, mouse_state.press_start_x, mouse_state.press_start_y)
    end
    
    if mouse_state.dragging then
        return mouse.update_drag_selection(ed, buf, x, y)
    end
    
    return false
end

function mouse.handle_release(ed, buf, x, y, button)
    if button == 1 and mouse_state.pressed then
        mouse_state.pressed = false
        
        if mouse_state.dragging then
            mouse_state.dragging = false
            
            if ed.selection.start_line == ed.selection.end_line and 
               ed.selection.start_col == ed.selection.end_col then
                editor.clear_selection(ed)
            end
        else
            local line, col = mouse.screen_to_editor_coords(x, y, ed)
            if line and col then
                line, col = mouse.clamp_to_buffer(line, col, buf)
                
                local current_time = love.timer.getTime()
                local time_since_last = current_time - mouse_state.last_click_time
                local same_position = (line == mouse_state.last_click_line and 
                                      math.abs(col - mouse_state.last_click_col) <= 1)
                
                local click_count = 1
                if time_since_last < mouse_state.double_click_threshold and same_position then
                    click_count = mouse_state.last_click_count + 1
                end
                
                if click_count == 1 then
                    editor.clear_selection(ed)
                    ed.cursor_line = line
                    ed.cursor_col = col
                    editor.update_viewport(ed, buf)
                elseif click_count == 2 then
                    mouse.select_word_at(ed, buf, line, col)
                elseif click_count >= 3 then
                    mouse.select_line_at(ed, buf, line)
                    click_count = 3
                end
                
                mouse_state.last_click_time = current_time
                mouse_state.last_click_line = line
                mouse_state.last_click_col = col
                mouse_state.last_click_count = click_count
            end
        end
        
        return true
    end
    return false
end

function mouse.handle_click(ed, buf, x, y, button, presses)
    return false
end

return mouse