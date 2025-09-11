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

function actions.delete_word_left(ed, buf)
    if editor.has_selection(ed) then
        actions.delete_selection(ed, buf)
        return
    end
    
    local line = buf.lines[ed.cursor_line]
    local start_col = ed.cursor_col
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

    if new_col < start_col then
        local deleted_text = string.sub(line, new_col + 1, start_col)
        local undo = require("undo")
        undo.record_deletion(ed.undo_state, ed.cursor_line, new_col, deleted_text, ed)
        
        buffer.delete_text(buf, ed.cursor_line, new_col, start_col - new_col)
        ed.cursor_col = new_col
        editor.update_viewport(ed, buf)
    end
end

function actions.delete_word_right(ed, buf)
    if editor.has_selection(ed) then
        actions.delete_selection(ed, buf)
        return
    end
    
    local line = buf.lines[ed.cursor_line]
    local start_col = ed.cursor_col
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

    if new_col > start_col then
        local deleted_text = string.sub(line, start_col + 1, new_col)
        local undo = require("undo")
        undo.record_deletion(ed.undo_state, ed.cursor_line, start_col, deleted_text, ed)
        
        buffer.delete_text(buf, ed.cursor_line, start_col, new_col - start_col)
        editor.update_viewport(ed, buf)
    end
end

function actions.duplicate_lines(ed, buf)
    local start_line, end_line
    
    if editor.has_selection(ed) then
        local bounds = editor.get_selection_bounds(ed)
        start_line = bounds.start_line
        end_line = bounds.end_line
    else
        start_line = ed.cursor_line
        end_line = ed.cursor_line
    end
    
    local lines_to_duplicate = {}
    for i = start_line, end_line do
        table.insert(lines_to_duplicate, buf.lines[i])
    end
    
    local undo = require("undo")
    undo.start_edit_group(ed.undo_state, ed)
    
    for i = #lines_to_duplicate, 1, -1 do
        table.insert(buf.lines, end_line + 1, lines_to_duplicate[i])
        undo.record_insertion(ed.undo_state, end_line + 1, 0, lines_to_duplicate[i] .. "\n", ed)
    end
    
    undo.finish_edit_group(ed.undo_state, ed)
    
    ed.cursor_line = end_line + #lines_to_duplicate
    
    if editor.has_selection(ed) then
        ed.selection.start_line = start_line + #lines_to_duplicate
        ed.selection.end_line = end_line + #lines_to_duplicate
        editor.update_selection(ed)
    end
    
    buffer.mark_dirty(buf)
    editor.update_viewport(ed, buf)
end

function actions.delete_line(ed, buf)
    if #buf.lines <= 1 then
        local undo = require("undo")
        local old_content = buf.lines[1]
        undo.record_deletion(ed.undo_state, 1, 0, old_content, ed)
        buf.lines[1] = ""
        ed.cursor_col = 0
        buffer.mark_dirty(buf)
        editor.clear_selection(ed)
        editor.update_viewport(ed, buf)
        return
    end
    
    local line_to_delete = ed.cursor_line
    local undo = require("undo")
    
    undo.record_deletion(ed.undo_state, line_to_delete, 0, buf.lines[line_to_delete] .. "\n", ed)
    table.remove(buf.lines, line_to_delete)
    
    if ed.cursor_line > #buf.lines then
        ed.cursor_line = #buf.lines
    end
    
    local line = buf.lines[ed.cursor_line]
    ed.cursor_col = math.min(ed.cursor_col, #line)
    
    buffer.mark_dirty(buf)
    editor.clear_selection(ed)
    editor.update_viewport(ed, buf)
end

function actions.move_lines_up(ed, buf)
    local start_line, end_line
    
    if editor.has_selection(ed) then
        local bounds = editor.get_selection_bounds(ed)
        start_line = bounds.start_line
        end_line = bounds.end_line
    else
        start_line = ed.cursor_line
        end_line = ed.cursor_line
    end
    
    if start_line <= 1 then
        return
    end
    
    local undo = require("undo")
    undo.start_edit_group(ed.undo_state, ed)
    
    local line_above = buf.lines[start_line - 1]
    table.remove(buf.lines, start_line - 1)
    table.insert(buf.lines, end_line, line_above)
    
    undo.record_deletion(ed.undo_state, start_line - 1, 0, line_above .. "\n", ed)
    undo.record_insertion(ed.undo_state, end_line, 0, line_above .. "\n", ed)
    
    undo.finish_edit_group(ed.undo_state, ed)
    
    ed.cursor_line = ed.cursor_line - 1
    
    if editor.has_selection(ed) then
        ed.selection.start_line = start_line - 1
        ed.selection.end_line = end_line - 1
        editor.update_selection(ed)
    end
    
    buffer.mark_dirty(buf)
    editor.update_viewport(ed, buf)
end

function actions.move_lines_down(ed, buf)
    local start_line, end_line
    
    if editor.has_selection(ed) then
        local bounds = editor.get_selection_bounds(ed)
        start_line = bounds.start_line
        end_line = bounds.end_line
    else
        start_line = ed.cursor_line
        end_line = ed.cursor_line
    end
    
    if end_line >= #buf.lines then
        return
    end
    
    local undo = require("undo")
    undo.start_edit_group(ed.undo_state, ed)
    
    local line_below = buf.lines[end_line + 1]
    table.remove(buf.lines, end_line + 1)
    table.insert(buf.lines, start_line, line_below)
    
    undo.record_deletion(ed.undo_state, end_line + 1, 0, line_below .. "\n", ed)
    undo.record_insertion(ed.undo_state, start_line, 0, line_below .. "\n", ed)
    
    undo.finish_edit_group(ed.undo_state, ed)
    
    ed.cursor_line = ed.cursor_line + 1
    
    if editor.has_selection(ed) then
        ed.selection.start_line = start_line + 1
        ed.selection.end_line = end_line + 1
        editor.update_selection(ed)
    end
    
    buffer.mark_dirty(buf)
    editor.update_viewport(ed, buf)
end

function actions.indent(ed, buf)
    local config = require("config")
    local tab_size = config.get("tab_size")
    local indent_using = config.get("indent_using")
    
    local indent_text
    if indent_using == "tabs" then
        indent_text = "\t"
    else
        indent_text = string.rep(" ", tab_size)
    end
    
    if editor.has_selection(ed) then
        local bounds = editor.get_selection_bounds(ed)
        local undo = require("undo")
        undo.start_edit_group(ed.undo_state, ed)
        
        for line_num = bounds.start_line, bounds.end_line do
            undo.record_insertion(ed.undo_state, line_num, 0, indent_text, ed)
            buf.lines[line_num] = indent_text .. buf.lines[line_num]
        end
        
        undo.finish_edit_group(ed.undo_state, ed)
        
        ed.selection.start_col = ed.selection.start_col + #indent_text
        ed.selection.end_col = ed.selection.end_col + #indent_text
        ed.cursor_col = ed.cursor_col + #indent_text
        
        buffer.mark_dirty(buf)
        editor.update_viewport(ed, buf)
    else
        local undo = require("undo")
        undo.record_insertion(ed.undo_state, ed.cursor_line, ed.cursor_col, indent_text, ed)
        
        ed.cursor_col = buffer.insert_text(buf, ed.cursor_line, ed.cursor_col, indent_text)
        editor.update_viewport(ed, buf)
    end
end

function actions.unindent(ed, buf)
    local config = require("config")
    local tab_size = config.get("tab_size")
    local indent_using = config.get("indent_using")
    
    if editor.has_selection(ed) then
        local bounds = editor.get_selection_bounds(ed)
        local undo = require("undo")
        undo.start_edit_group(ed.undo_state, ed)
        
        for line_num = bounds.start_line, bounds.end_line do
            local line = buf.lines[line_num]
            local removed = 0
            
            if indent_using == "tabs" then
                if line:sub(1, 1) == "\t" then
                    undo.record_deletion(ed.undo_state, line_num, 0, "\t", ed)
                    buf.lines[line_num] = line:sub(2)
                    removed = 1
                end
            else
                local spaces_to_remove = 0
                for i = 1, math.min(tab_size, #line) do
                    if line:sub(i, i) == " " then
                        spaces_to_remove = spaces_to_remove + 1
                    else
                        break
                    end
                end
                
                if spaces_to_remove > 0 then
                    local removed_text = line:sub(1, spaces_to_remove)
                    undo.record_deletion(ed.undo_state, line_num, 0, removed_text, ed)
                    buf.lines[line_num] = line:sub(spaces_to_remove + 1)
                    removed = spaces_to_remove
                end
            end
            
            if line_num == bounds.start_line then
                ed.selection.start_col = math.max(0, ed.selection.start_col - removed)
            end
            if line_num == bounds.end_line then
                ed.selection.end_col = math.max(0, ed.selection.end_col - removed)
            end
        end
        
        undo.finish_edit_group(ed.undo_state, ed)
        ed.cursor_col = math.max(0, ed.cursor_col - (indent_using == "tabs" and 1 or tab_size))
        
        buffer.mark_dirty(buf)
        editor.update_viewport(ed, buf)
    else
        local line = buf.lines[ed.cursor_line]
        local removed = 0
        
        local undo = require("undo")
        
        if indent_using == "tabs" then
            if line:sub(1, 1) == "\t" then
                undo.record_deletion(ed.undo_state, ed.cursor_line, 0, "\t", ed)
                buf.lines[ed.cursor_line] = line:sub(2)
                removed = 1
            end
        else
            local spaces_to_remove = 0
            for i = 1, math.min(tab_size, #line) do
                if line:sub(i, i) == " " then
                    spaces_to_remove = spaces_to_remove + 1
                else
                    break
                end
            end
            
            if spaces_to_remove > 0 then
                local removed_text = line:sub(1, spaces_to_remove)
                undo.record_deletion(ed.undo_state, ed.cursor_line, 0, removed_text, ed)
                buf.lines[ed.cursor_line] = line:sub(spaces_to_remove + 1)
                removed = spaces_to_remove
            end
        end
        
        ed.cursor_col = math.max(0, ed.cursor_col - removed)
        buffer.mark_dirty(buf)
        editor.update_viewport(ed, buf)
    end
end

function actions.tab_or_indent(ed, buf)
    local config = require("config")
    local tab_size = config.get("tab_size")
    
    local line = buf.lines[ed.cursor_line]
    local before_cursor = line:sub(1, ed.cursor_col)
    
    if before_cursor:match("^%s*$") then
        actions.indent(ed, buf)
    else
        local spaces_needed = tab_size - (ed.cursor_col % tab_size)
        local spaces = string.rep(" ", spaces_needed)
        
        local undo = require("undo")
        undo.record_insertion(ed.undo_state, ed.cursor_line, ed.cursor_col, spaces, ed)
        
        ed.cursor_col = buffer.insert_text(buf, ed.cursor_line, ed.cursor_col, spaces)
        editor.update_viewport(ed, buf)
    end
end

return actions