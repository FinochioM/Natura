local editor = {}

function editor.create()
    return {
        cursor_line = 1,
        cursor_col = 0
    }
end

function editor.move_cursor_left(ed, buf)
    if ed.cursor_col > 0 then
        ed.cursor_col = ed.cursor_col - 1
    elseif ed.cursor_line > 1 then
        ed.cursor_line = ed.cursor_line - 1
        ed.cursor_col = #buf.lines[ed.cursor_line]
    end
end

function editor.move_cursor_right(ed, buf)
    local line = buf.lines[ed.cursor_line]
    if ed.cursor_col < #line then
        ed.cursor_col = ed.cursor_col + 1
    elseif ed.cursor_line < #buf.lines then
        ed.cursor_line = ed.cursor_line + 1
        ed.cursor_col = 0
    end
end

function editor.move_cursor_up(ed, buf)
    if ed.cursor_line > 1 then
        ed.cursor_line = ed.cursor_line - 1
        local line = buf.lines[ed.cursor_line]
        ed.cursor_col = math.min(ed.cursor_col, #line)
    end
end

function editor.move_cursor_down(ed, buf)
    if ed.cursor_line < #buf.lines then
        ed.cursor_line = ed.cursor_line + 1
        local line = buf.lines[ed.cursor_line]
        ed.cursor_col = math.min(ed.cursor_col, #line)
    end
end

return editor