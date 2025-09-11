local undo = {}

function undo.create()
    return {
        undo_stack = {},
        redo_stack = {},
        current_group = nil,
        last_action_time = 0
    }
end

function undo.start_edit_group(undo_state, editor)
    if undo_state.current_group then
        undo.finish_edit_group(undo_state)
    end
    
    undo_state.current_group = {
        edits = {},
        cursor_before = {
            line = editor.cursor_line,
            col = editor.cursor_col
        },
        cursor_after = nil
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
    
    if #undo_state.undo_stack > 100 then
        table.remove(undo_state.undo_stack, 1)
    end
    
    undo_state.current_group = nil
end

function undo.should_group_with_previous(undo_state)
    local current_time = love.timer.getTime()
    local time_diff = current_time - undo_state.last_action_time
    undo_state.last_action_time = current_time
    
    return time_diff < 1.0 and undo_state.current_group ~= nil
end

function undo.record_insertion(undo_state, line, col, text, editor)
    if not undo.should_group_with_previous(undo_state) then
        undo.start_edit_group(undo_state, editor)
    end
    
    table.insert(undo_state.current_group.edits, {
        type = "insert",
        line = line,
        col = col,
        text = text
    })
end

function undo.record_deletion(undo_state, line, col, text, editor)
    if not undo.should_group_with_previous(undo_state) then
        undo.start_edit_group(undo_state, editor)
    end
    
    table.insert(undo_state.current_group.edits, {
        type = "delete",
        line = line,
        col = col,
        text = text
    })
end

function undo.perform_undo(undo_state, editor, buffer_obj)
    undo.finish_edit_group(undo_state)
    
    if #undo_state.undo_stack == 0 then
        return false
    end
    
    local edit_group = table.remove(undo_state.undo_stack)
    local buffer_module = require("buffer")
    
    for i = #edit_group.edits, 1, -1 do
        local edit = edit_group.edits[i]
        if edit.type == "insert" then
            buffer_module.delete_text(buffer_obj, edit.line, edit.col, #edit.text)
        elseif edit.type == "delete" then
            buffer_module.insert_text(buffer_obj, edit.line, edit.col, edit.text)
        end
    end
    
    editor.cursor_line = edit_group.cursor_before.line
    editor.cursor_col = edit_group.cursor_before.col
    
    table.insert(undo_state.redo_stack, edit_group)
    
    require("editor").update_viewport(editor, buffer_obj)
    return true
end

function undo.perform_redo(undo_state, editor, buffer_obj)
    if #undo_state.redo_stack == 0 then
        return false
    end
    
    local edit_group = table.remove(undo_state.redo_stack)
    local buffer_module = require("buffer")
    
    for i = 1, #edit_group.edits do
        local edit = edit_group.edits[i]
        if edit.type == "insert" then
            buffer_module.insert_text(buffer_obj, edit.line, edit.col, edit.text)
        elseif edit.type == "delete" then
            buffer_module.delete_text(buffer_obj, edit.line, edit.col, #edit.text)
        end
    end
    
    if edit_group.cursor_after then
        editor.cursor_line = edit_group.cursor_after.line
        editor.cursor_col = edit_group.cursor_after.col
    end
    
    table.insert(undo_state.undo_stack, edit_group)
    
    require("editor").update_viewport(editor, buffer_obj)
    return true
end

return undo