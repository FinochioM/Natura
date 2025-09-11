local actions = {}
local buffer = require("buffer")
local editor = require("editor")

local clipboard_text = ""

function actions.copy(ed, buf)
    if editor.has_selection(ed) then
        clipboard_text = editor.get_selected_text(ed, buf)
    else
        clipboard_text = buf.lines[ed.cursor_line] or ""
    end
    print("Copied: " .. clipboard_text:sub(1, 50) .. (clipboard_text:len() > 50 and "..." or ""))
end

function actions.paste(ed, buf)
    if clipboard_text ~= "" then
        if editor.has_selection(ed) then
            actions.delete_selection(ed, buf)
        end

        local lines = {}
        for line in clipboard_text:gmatch("([^\n]*)\n?") do
            table.insert(lines, line)
        end

        if #lines == 1 then
            ed.cursor_col = buffer.insert_text(buf, ed.cursor_line, ed.cursor_col, lines[1])
        else
            local current_line = buf.lines[ed.cursor_line]
            local before = string.sub(current_line, 1, ed.cursor_col)
            local after = string.sub(current_line, ed.cursor_col + 1)

            buf.lines[ed.cursor_line] = before .. lines[1]

            for i = 2, #lines - 1 do
                table.insert(buf.lines, ed.cursor_line + i - 1, lines[i])
            end

            if #lines > 1 then
                table.insert(buf.lines, ed.cursor_line + #lines - 1, lines[#lines] .. after)
                ed.cursor_line = ed.cursor_line + #lines - 1
                ed.cursor_col = #lines[#lines]
            end

            buffer.mark_dirty(buf)
        end

        editor.clear_selection(ed)
        editor.update_viewport(ed, buf)
    end
end

function actions.cut(ed, buf)
    actions.copy(ed, buf)
    if editor.has_selection(ed) then
        actions.delete_selection(ed, buf)
    else
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
    end
end

function actions.delete_selection(ed, buf)
    local bounds = editor.get_selection_bounds(ed)
    if not bounds then return end

    if bounds.start_line == bounds.end_line then
        local line = buf.lines[bounds.start_line]
        local before = string.sub(line, 1, bounds.start_col)
        local after = string.sub(line, bounds.end_col + 1)
        buf.lines[bounds.start_line] = before .. after
    else
        local first_line = buf.lines[bounds.start_line]
        local last_line = buf.lines[bounds.end_line]
        local before = string.sub(first_line, 1, bounds.start_col)
        local after = string.sub(last_line, bounds.end_col + 1)

        for i = bounds.end_line, bounds.start_line + 1, -1 do
            table.remove(buf.lines, i)
        end

        buf.lines[bounds.start_line] = before .. after
    end

    ed.cursor_line = bounds.start_line
    ed.cursor_col = bounds.start_col
    editor.clear_selection(ed)
    buffer.mark_dirty(buf)
end

function actions.select_all(ed, buf)
    editor.select_all(ed, buf)
end

function actions.select_word(ed, buf)
    editor.select_word(ed, buf)
end

function actions.jump_to_line_start(ed, buf, extend_selection)
    if not extend_selection then
        editor.clear_selection(ed)
    elseif not ed.selection.active then
        editor.start_selection(ed)
    end

    ed.cursor_col = 0

    if extend_selection then
        editor.update_selection(ed)
    end
    editor.update_viewport(ed, buf)
end

function actions.jump_to_line_end(ed, buf, extend_selection)
    if not extend_selection then
        editor.clear_selection(ed)
    elseif not ed.selection.active then
        editor.start_selection(ed)
    end

    ed.cursor_col = #buf.lines[ed.cursor_line]

    if extend_selection then
        editor.update_selection(ed)
    end
    editor.update_viewport(ed, buf)
end

function actions.jump_to_file_start(ed, buf, extend_selection)
    if not extend_selection then
        editor.clear_selection(ed)
    elseif not ed.selection.active then
        editor.start_selection(ed)
    end

    ed.cursor_line = 1
    ed.cursor_col = 0

    if extend_selection then
        editor.update_selection(ed)
    end
    editor.update_viewport(ed, buf)
end

function actions.jump_to_file_end(ed, buf, extend_selection)
    if not extend_selection then
        editor.clear_selection(ed)
    elseif not ed.selection.active then
        editor.start_selection(ed)
    end

    ed.cursor_line = #buf.lines
    ed.cursor_col = #buf.lines[ed.cursor_line]

    if extend_selection then
        editor.update_selection(ed)
    end
    editor.update_viewport(ed, buf)
end

function actions.delete_to_line_end(ed, buf)
    local line = buf.lines[ed.cursor_line]
    buf.lines[ed.cursor_line] = string.sub(line, 1, ed.cursor_col)
    buffer.mark_dirty(buf)
    editor.clear_selection(ed)
end

function actions.delete_to_line_start(ed, buf)
    local line = buf.lines[ed.cursor_line]
    buf.lines[ed.cursor_line] = string.sub(line, ed.cursor_col + 1)
    ed.cursor_col = 0
    buffer.mark_dirty(buf)
    editor.clear_selection(ed)
end

function actions.move_word_left(ed, buf, extend_selection)
    if not extend_selection then
        editor.clear_selection(ed)
    elseif not ed.selection.active then
        editor.start_selection(ed)
    end

    local line = buf.lines[ed.cursor_line]
    local new_col = ed.cursor_col

    if new_col > 0 then
        new_col = new_col - 1
        
        while new_col > 0 and string.match(string.sub(line, new_col + 1, new_col + 1), "%s") do
            new_col = new_col - 1
        end
        
        if new_col > 0 then
            local char = string.sub(line, new_col + 1, new_col + 1)
            if string.match(char, "%w") then
                while new_col > 0 and string.match(string.sub(line, new_col, new_col), "%w") do
                    new_col = new_col - 1
                end
            else
                while new_col > 0 and not string.match(string.sub(line, new_col, new_col), "[%w%s]") do
                    new_col = new_col - 1
                end
            end
        end
    end

    ed.cursor_col = new_col

    if extend_selection then
        editor.update_selection(ed)
    end
    editor.update_viewport(ed, buf)
end

function actions.move_word_right(ed, buf, extend_selection)
    if not extend_selection then
        editor.clear_selection(ed)
    elseif not ed.selection.active then
        editor.start_selection(ed)
    end

    local line = buf.lines[ed.cursor_line]
    local new_col = ed.cursor_col

    if new_col < #line then
        local char = string.sub(line, new_col + 1, new_col + 1)
        
        if string.match(char, "%w") then
            while new_col < #line and string.match(string.sub(line, new_col + 1, new_col + 1), "%w") do
                new_col = new_col + 1
            end
        elseif string.match(char, "%s") then
            while new_col < #line and string.match(string.sub(line, new_col + 1, new_col + 1), "%s") do
                new_col = new_col + 1
            end
        else
            while new_col < #line and not string.match(string.sub(line, new_col + 1, new_col + 1), "[%w%s]") do
                new_col = new_col + 1
            end
        end
        
        while new_col < #line and string.match(string.sub(line, new_col + 1, new_col + 1), "%s") do
            new_col = new_col + 1
        end
    end

    ed.cursor_col = new_col

    if extend_selection then
        editor.update_selection(ed)
    end
    editor.update_viewport(ed, buf)
end

function actions.undo(ed, buf)
    local undo = require("undo")
    undo.perform_undo(ed.undo_state, ed, buf)
end

function actions.redo(ed, buf)
    local undo = require("undo")
    undo.perform_redo(ed.undo_state, ed, buf)
end

return actions