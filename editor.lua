local editor = {}

function editor.create()
    return {
        cursor_line = 1,
        cursor_col = 0,
        viewport = {
            top_line = 1,  -- First visible line
            left_col = 0   -- Horizontal scroll (for future use)
        }
    }
end

function editor.get_visible_line_count()
    local font = love.graphics.getFont()
    local window_height = love.graphics.getHeight()
    local content_start_y = 40
    local available_height = window_height - content_start_y
    return math.floor(available_height / font:getHeight())
end

function editor.update_viewport(ed, buf)
    local visible_lines = editor.get_visible_line_count()
    
    if ed.cursor_line >= ed.viewport.top_line + visible_lines then
        ed.viewport.top_line = ed.cursor_line - visible_lines + 1
    end
    
    if ed.cursor_line < ed.viewport.top_line then
        ed.viewport.top_line = ed.cursor_line
    end
    
    ed.viewport.top_line = math.max(1, ed.viewport.top_line)
    
    local max_top_line = math.max(1, #buf.lines - visible_lines + 1)
    ed.viewport.top_line = math.min(ed.viewport.top_line, max_top_line)
end

function editor.scroll_up(ed, buf, lines)
    lines = lines or 1
    ed.viewport.top_line = math.max(1, ed.viewport.top_line - lines)
end

function editor.scroll_down(ed, buf, lines)
    lines = lines or 1
    local visible_lines = editor.get_visible_line_count()
    local max_top_line = math.max(1, #buf.lines - visible_lines + 1)
    ed.viewport.top_line = math.min(max_top_line, ed.viewport.top_line + lines)
end

function editor.move_cursor_left(ed, buf)
    if ed.cursor_col > 0 then
        ed.cursor_col = ed.cursor_col - 1
    elseif ed.cursor_line > 1 then
        ed.cursor_line = ed.cursor_line - 1
        ed.cursor_col = #buf.lines[ed.cursor_line]
    end
    editor.update_viewport(ed, buf)
end

function editor.move_cursor_right(ed, buf)
    local line = buf.lines[ed.cursor_line]
    if ed.cursor_col < #line then
        ed.cursor_col = ed.cursor_col + 1
    elseif ed.cursor_line < #buf.lines then
        ed.cursor_line = ed.cursor_line + 1
        ed.cursor_col = 0
    end
    editor.update_viewport(ed, buf)
end

function editor.move_cursor_up(ed, buf)
    if ed.cursor_line > 1 then
        ed.cursor_line = ed.cursor_line - 1
        local line = buf.lines[ed.cursor_line]
        ed.cursor_col = math.min(ed.cursor_col, #line)
    end
    editor.update_viewport(ed, buf)
end

function editor.move_cursor_down(ed, buf)
    if ed.cursor_line < #buf.lines then
        ed.cursor_line = ed.cursor_line + 1
        local line = buf.lines[ed.cursor_line]
        ed.cursor_col = math.min(ed.cursor_col, #line)
    end
    editor.update_viewport(ed, buf)
end

function editor.page_up(ed, buf)
    local visible_lines = editor.get_visible_line_count()
    ed.cursor_line = math.max(1, ed.cursor_line - visible_lines)
    local line = buf.lines[ed.cursor_line]
    ed.cursor_col = math.min(ed.cursor_col, #line)
    editor.update_viewport(ed, buf)
end

function editor.page_down(ed, buf)
    local visible_lines = editor.get_visible_line_count()
    ed.cursor_line = math.min(#buf.lines, ed.cursor_line + visible_lines)
    local line = buf.lines[ed.cursor_line]
    ed.cursor_col = math.min(ed.cursor_col, #line)
    editor.update_viewport(ed, buf)
end

return editor