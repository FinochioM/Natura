local mouse = {}

local editor = require("editor")
local buffer = require("buffer")

local mouse_state = {
    dragging = false,
    drag_start_line = 1,
    drag_start_col = 0,
    last_click_time = 0,
    last_click_line = 1,
    last_click_col = 0,
    double_click_threshold = 0.5
}

function mouse.screen_to_editor_coords(x, y)
    local font = love.graphics.getFont()
    local line_height = font:getHeight()
    local content_start_y = 40
    local char_width = font:getWidth("W")
    
    if y < content_start_y then
        return nil, nil
    end
    
    local line = math.floor((y - content_start_y) / line_height) + 1
    local col = math.max(0, math.floor((x - 10) / char_width))
    
    return line, col
end

function mouse.position_cursor_at_coords(ed, buf, screen_x, screen_y)
    local line, col = mouse.screen_to_editor_coords(screen_x, screen_y)
    if not line or not col then return false end
    
    line = line + ed.viewport.top_line - 1
    
    line = math.max(1, math.min(line, #buf.lines))
    col = math.max(0, math.min(col, #buf.lines[line]))
    
    ed.cursor_line = line
    ed.cursor_col = col
    
    editor.update_viewport(ed, buf)
    return true
end

function mouse.start_selection(ed, buf, screen_x, screen_y)
    local line, col = mouse.screen_to_editor_coords(screen_x, screen_y)
    if not line or not col then return false end
    
    line = line + ed.viewport.top_line - 1
    line = math.max(1, math.min(line, #buf.lines))
    col = math.max(0, math.min(col, #buf.lines[line]))
    
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
    
    return true
end

function mouse.update_selection(ed, buf, screen_x, screen_y)
    if not mouse_state.dragging then return false end
    
    local line, col = mouse.screen_to_editor_coords(screen_x, screen_y)
    if not line or not col then return false end
    
    line = line + ed.viewport.top_line - 1
    line = math.max(1, math.min(line, #buf.lines))
    col = math.max(0, math.min(col, #buf.lines[line]))
    
    ed.selection.end_line = line
    ed.selection.end_col = col
    ed.cursor_line = line
    ed.cursor_col = col
    
    editor.update_viewport(ed, buf)
    return true
end

function mouse.end_selection()
    mouse_state.dragging = false
end

function mouse.select_word(ed, buf, line, col)
    local line_text = buf.lines[line]
    local start_col = col
    local end_col = col
    
    while start_col > 0 and line_text:sub(start_col, start_col):match("%w") do
        start_col = start_col - 1
    end
    while end_col < #line_text and line_text:sub(end_col + 1, end_col + 1):match("%w") do
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

function mouse.select_line(ed, buf, line)
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
    
    local line, col = mouse.screen_to_editor_coords(x, y)
    if not line or not col then return false end
    
    line = line + ed.viewport.top_line - 1
    line = math.max(1, math.min(line, #buf.lines))
    col = math.max(0, math.min(col, #buf.lines[line]))
    
    local current_time = love.timer.getTime()
    local time_since_last = current_time - mouse_state.last_click_time
    local same_position = (line == mouse_state.last_click_line and col == mouse_state.last_click_col)
    
    if button == 1 then
        if presses == 2 or (time_since_last < mouse_state.double_click_threshold and same_position) then
            mouse.select_word(ed, buf, line, col)
        elseif presses == 3 or (time_since_last < mouse_state.double_click_threshold * 2 and same_position) then
            mouse.select_line(ed, buf, line)
        else
            editor.clear_selection(ed)
            mouse.position_cursor_at_coords(ed, buf, x, y)
        end
        
        mouse_state.last_click_time = current_time
        mouse_state.last_click_line = line
        mouse_state.last_click_col = col
        
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
        return mouse.start_selection(ed, buf, x, y)
    end
    return false
end

function mouse.handle_release(ed, buf, x, y, button)
    if button == 1 and mouse_state.dragging then
        mouse.end_selection()
        return true
    end
    return false
end

return mouse