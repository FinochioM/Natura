local mouse = {}

local editor = require("editor")

local mouse_state = {
    dragging = false,
    drag_start_line = 1,
    drag_start_col = 0,
    last_click_time = 0,
    last_click_line = 1,
    last_click_col = 0,
    last_click_count = 0,
    double_click_threshold = 0.4
}

function mouse.screen_to_editor_coords(x, y, ed)
    local font = love.graphics.getFont()
    local line_height = font:getHeight()
    local content_start_y = 40
    local text_start_x = 10
    
    if y < content_start_y then
        return nil, nil
    end
    
    local relative_y = y - content_start_y
    local line_offset = math.floor(relative_y / line_height)
    local line = ed.viewport.top_line + line_offset
    
    local relative_x = x - text_start_x
    local char_width = font:getWidth("W")
    local col = math.max(0, math.floor((relative_x + char_width * 0.5) / char_width))
    
    return line, col
end

function mouse.clamp_to_buffer(line, col, buf)
    line = math.max(1, math.min(line, #buf.lines))
    col = math.max(0, math.min(col, #buf.lines[line]))
    return line, col
end

function mouse.position_cursor_at_coords(ed, buf, screen_x, screen_y)
    local line, col = mouse.screen_to_editor_coords(screen_x, screen_y, ed)
    if not line or not col then return false end
    
    line, col = mouse.clamp_to_buffer(line, col, buf)
    
    ed.cursor_line = line
    ed.cursor_col = col
    
    editor.update_viewport(ed, buf)
    return true
end

function mouse.start_selection(ed, buf, screen_x, screen_y)
    local line, col = mouse.screen_to_editor_coords(screen_x, screen_y, ed)
    if not line or not col then return false end
    
    line, col = mouse.clamp_to_buffer(line, col, buf)
    
    mouse_state.dragging = true
    mouse_state.drag_start_line = line
    mouse_state.drag_start_col = col
    
    ed.selection.active = true
    ed.selection.start_line = line
    ed.selection.start_col = col
    ed.selection.end_line = line
    ed.selection.end_col = col
    
    ed.cursor_line = line
    ed.cursor_col = col
    
    editor.update_viewport(ed, buf)
    return true
end

function mouse.update_selection(ed, buf, screen_x, screen_y)
    if not mouse_state.dragging then return false end
    
    local line, col = mouse.screen_to_editor_coords(screen_x, screen_y, ed)
    if not line or not col then return false end
    
    line, col = mouse.clamp_to_buffer(line, col, buf)
    
    ed.selection.end_line = line
    ed.selection.end_col = col
    
    ed.cursor_line = line
    ed.cursor_col = col
    
    editor.update_viewport(ed, buf)
    return true
end

function mouse.end_selection(ed)
    mouse_state.dragging = false
    
    if ed.selection.start_line == ed.selection.end_line and 
       ed.selection.start_col == ed.selection.end_col then
        editor.clear_selection(ed)
    end
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

function mouse.handle_click(ed, buf, x, y, button, presses)
    if y < 40 then return false end
    
    local line, col = mouse.screen_to_editor_coords(x, y, ed)
    if not line or not col then return false end
    
    line, col = mouse.clamp_to_buffer(line, col, buf)
    
    local current_time = love.timer.getTime()
    local time_since_last = current_time - mouse_state.last_click_time
    local same_position = (line == mouse_state.last_click_line and 
                          math.abs(col - mouse_state.last_click_col) <= 1)
    
    if button == 1 then
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
        
        return true
    end
    
    return false
end

function mouse.handle_drag(ed, buf, x, y, dx, dy)
    if mouse_state.dragging then
        return mouse.update_selection(ed, buf, x, y)
    end
    return false
end

function mouse.handle_press(ed, buf, x, y, button)
    if button == 1 and not mouse_state.dragging then
        local current_time = love.timer.getTime()
        local time_since_last = current_time - mouse_state.last_click_time
        
        if time_since_last >= mouse_state.double_click_threshold then
            return mouse.start_selection(ed, buf, x, y)
        end
    end
    return false
end

function mouse.handle_release(ed, buf, x, y, button)
    if button == 1 and mouse_state.dragging then
        mouse.end_selection(ed)
        return true
    end
    return false
end

return mouse