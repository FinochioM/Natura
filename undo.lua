local undo = {}

function undo.create()
    return {
        undo_stack = {},
        redo_stack = {},
        current_group = nil,
        last_action_time = 0,
        group_timeout = 1.0
    }
end

function undo.start_edit_group(undo_state, editor)
    undo_state.current_group = {
        edits = {},
        cursor_before = {
            line = editor.cursor_line,
            col = editor.cursor_col
        }
    }
    undo_state.last_action_time = love.timer.getTime()
end

function undo.finish_edit_group(undo_state, editor)
    if not undo_state.current_group or #undo_state.current_group.edits == 0 then
        undo_state.current_group = nil
        return
    end
    
    undo_state.current_group.cursor_after = {
        line = editor.cursor_line,
        col = editor.cursor_col
    }
    
    table.insert(undo_state.undo_stack, undo_state.current_group)
    undo_state.redo_stack = {}
    
    while #undo_state.undo_stack > 100 do
        table.remove(undo_state.undo_stack, 1)
    end
    
    undo_state.current_group = nil
end

function undo.new_edit_group(undo_state, editor)
    undo.finish_edit_group(undo_state, editor)
end

function undo.record_insertion(undo_state, line, col, text, editor)
    if not undo_state.current_group then
        undo.start_edit_group(undo_state, editor)
    end
    
    table.insert(undo_state.current_group.edits, {
        type = "insert",
        line = line,
        col = col,
        text = text
    })
    
    undo_state.last_action_time = love.timer.getTime()
end

function undo.record_deletion(undo_state, line, col, text, editor)
    if not undo_state.current_group then
        undo.start_edit_group(undo_state, editor)
    end
    
    table.insert(undo_state.current_group.edits, {
        type = "delete",
        line = line,
        col = col,
        text = text
    })
    
    undo_state.last_action_time = love.timer.getTime()
end

local function insert_text_raw(buffer_obj, line, col, text)
    if line < 1 or line > #buffer_obj.lines then return end
    local line_content = buffer_obj.lines[line]
    local before = string.sub(line_content, 1, col)
    local after = string.sub(line_content, col + 1)
    buffer_obj.lines[line] = before .. text .. after
    require("buffer").mark_dirty(buffer_obj)
end

local function delete_text_raw(buffer_obj, line, col, length)
    if line < 1 or line > #buffer_obj.lines then return end
    local line_content = buffer_obj.lines[line]
    if col < 0 or col >= #line_content then return end
    
    local end_col = math.min(col + length, #line_content)
    buffer_obj.lines[line] = string.sub(line_content, 1, col) .. string.sub(line_content, end_col + 1)
    require("buffer").mark_dirty(buffer_obj)
end

function undo.perform_undo(undo_state, editor, buffer_obj)
    undo.new_edit_group(undo_state, editor)

    if #undo_state.undo_stack == 0 then
        return false
    end
    
    local edit_group = table.remove(undo_state.undo_stack)
    
    for i = #edit_group.edits, 1, -1 do
        local edit = edit_group.edits[i]
        if edit.type == "insert" then
            delete_text_raw(buffer_obj, edit.line, edit.col, #edit.text)
        elseif edit.type == "delete" then
            insert_text_raw(buffer_obj, edit.line, edit.col, edit.text)
        end
    end
    
    if edit_group.cursor_before then
        editor.cursor_line = edit_group.cursor_before.line
        editor.cursor_col = edit_group.cursor_before.col
    end
    
    table.insert(undo_state.redo_stack, edit_group)
    
    local editor_module = require("editor")
    editor_module.update_viewport(editor, buffer_obj)
    editor_module.clear_selection(editor)
    
    return true
end

function undo.perform_redo(undo_state, editor, buffer_obj)
    if #undo_state.redo_stack == 0 then
        return false
    end
    
    local edit_group = table.remove(undo_state.redo_stack)
    
    for i = 1, #edit_group.edits do
        local edit = edit_group.edits[i]
        if edit.type == "insert" then
            insert_text_raw(buffer_obj, edit.line, edit.col, edit.text)
        elseif edit.type == "delete" then
            delete_text_raw(buffer_obj, edit.line, edit.col, #edit.text)
        end
    end
    
    if edit_group.cursor_after then
        editor.cursor_line = edit_group.cursor_after.line
        editor.cursor_col = edit_group.cursor_after.col
    end
    
    table.insert(undo_state.undo_stack, edit_group)
    
    local editor_module = require("editor")
    editor_module.update_viewport(editor, buffer_obj)
    editor_module.clear_selection(editor)
    
    return true
end

return undo