local actions = {}
local buffer = require("buffer")
local editor = require("editor")

local clipboard_text = ""

function actions.copy(ed, buf)
    -- For now, just store in internal clipboard
    -- TODO: Add selection support first
    clipboard_text = buf.lines[ed.cursor_line] or ""
    print("Copied: " .. clipboard_text)
end

function actions.paste(ed, buf)
    if clipboard_text ~= "" then
        ed.cursor_col = buffer.insert_text(buf, ed.cursor_line, ed.cursor_col, clipboard_text)
        editor.update_viewport(ed, buf)
    end
end

function actions.cut(ed, buf)
    clipboard_text = buf.lines[ed.cursor_line] or ""
    if #buf.lines > 1 then
        table.remove(buf.lines, ed.cursor_line)
        if ed.cursor_line > #buf.lines then
            ed.cursor_line = #buf.lines
        end
        ed.cursor_col = 0
        buffer.mark_dirty(buf)
    else
        buf.lines[1] = ""
        ed.cursor_col = 0
        buffer.mark_dirty(buf)
    end
    editor.update_viewport(ed, buf)
    print("Cut: " .. clipboard_text)
end

function actions.select_all(ed, buf)
    -- TODO: Implement selection system
    print("Select all - not implemented yet")
end

function actions.jump_to_line_start(ed, buf)
    ed.cursor_col = 0
    editor.update_viewport(ed, buf)
end

function actions.jump_to_line_end(ed, buf)
    ed.cursor_col = #buf.lines[ed.cursor_line]
    editor.update_viewport(ed, buf)
end

function actions.jump_to_file_start(ed, buf)
    ed.cursor_line = 1
    ed.cursor_col = 0
    editor.update_viewport(ed, buf)
end

function actions.jump_to_file_end(ed, buf)
    ed.cursor_line = #buf.lines
    ed.cursor_col = #buf.lines[ed.cursor_line]
    editor.update_viewport(ed, buf)
end

function actions.delete_to_line_end(ed, buf)
    local line = buf.lines[ed.cursor_line]
    buf.lines[ed.cursor_line] = string.sub(line, 1, ed.cursor_col)
    buffer.mark_dirty(buf)
end

function actions.delete_to_line_start(ed, buf)
    local line = buf.lines[ed.cursor_line]
    buf.lines[ed.cursor_line] = string.sub(line, ed.cursor_col + 1)
    ed.cursor_col = 0
    buffer.mark_dirty(buf)
end

function actions.move_word_left(ed, buf)
    local line = buf.lines[ed.cursor_line]
    local new_col = ed.cursor_col
    
    while new_col > 0 and string.match(string.sub(line, new_col, new_col), "%w") do
        new_col = new_col - 1
    end
    while new_col > 0 and string.match(string.sub(line, new_col, new_col), "%s") do
        new_col = new_col - 1
    end
    
    ed.cursor_col = new_col
    editor.update_viewport(ed, buf)
end

function actions.move_word_right(ed, buf)
    local line = buf.lines[ed.cursor_line]
    local new_col = ed.cursor_col
    
    while new_col < #line and string.match(string.sub(line, new_col + 1, new_col + 1), "%w") do
        new_col = new_col + 1
    end
    while new_col < #line and string.match(string.sub(line, new_col + 1, new_col + 1), "%s") do
        new_col = new_col + 1
    end
    
    ed.cursor_col = new_col
    editor.update_viewport(ed, buf)
end

return actions