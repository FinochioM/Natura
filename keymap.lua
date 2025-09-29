local keymap = {}
local actions = require("actions")
local search = require("search")

local current_keybinds = {}

function keymap.load_keybinds()
    local config = require("config")
    
    current_keybinds = config.get("keybinds") or {}
    
    if not next(current_keybinds) then
        error("FATAL: No keybinds loaded from config!")
    end
end

local function get_key_string(key, ctrl, shift, alt)
    local parts = {}
    
    if ctrl then table.insert(parts, "ctrl") end
    if shift then table.insert(parts, "shift") end  
    if alt then table.insert(parts, "alt") end
    table.insert(parts, key)
    
    return table.concat(parts, "+")
end

function keymap.execute_action(action, ed, buf, shift, ctrl, alt)
    if action == "save" then
        require("buffer").save_file(buf, ed)
        return true
    elseif action == "create_new_file" then
        local buffer = require("buffer")
        buffer.create_new_file(buf)
        ed.cursor_line = 1
        ed.cursor_col = 0
        require("editor").clear_selection(ed)
        require("editor").update_viewport(ed, buf)
        return true
    elseif action == "search" then
        ed.goto_state.active = false 
        ed.search.active = true
        if require("editor").has_selection(ed) then
            ed.search.query = require("editor").get_selected_text(ed, buf)
            search.set_query(ed.search, ed.search.query, buf)
        end
        return true
    elseif action == "show_actions" then
        local actions_menu = require("actions_menu")
        actions_menu.toggle(ed.actions_menu)
        return true
    elseif action == "goto_line" then
        search.close(ed.search)
        local goto_module = require("goto")
        goto_module.toggle(ed.goto_state)
        return true
    elseif action == "copy" then
        actions.copy(ed, buf)
        return true
    elseif action == "paste" then
        actions.paste(ed, buf)
        return true
    elseif action == "cut" then
        actions.cut(ed, buf)
        return true
    elseif action == "select_all" then
        actions.select_all(ed, buf)
        return true
    elseif action == "select_word" then
        actions.select_word(ed, buf)
        return true
    elseif action == "open_file" then
        local file_dialog = require("file_dialog")
        file_dialog.toggle(ed.file_dialog)
        return true
    elseif action == "undo" then
        actions.undo(ed, buf)
        return true
    elseif action == "redo" then
        actions.redo(ed, buf)
        return true
    elseif action == "delete_to_line_end" then
        actions.delete_to_line_end(ed, buf)
        return true
    elseif action == "delete_to_line_start" then
        actions.delete_to_line_start(ed, buf)
        return true
    elseif action == "delete_word_left" then
        actions.delete_word_left(ed, buf)
        return true
    elseif action == "delete_word_right" then
        actions.delete_word_right(ed, buf)
        return true
    elseif action == "duplicate_lines" then
        actions.duplicate_lines(ed, buf)
        return true
    elseif action == "toggle_comment" then
        actions.toggle_comment(ed, buf)
        return true
    elseif action == "find_next" then
        if #ed.search.results > 0 then
            search.goto_next(ed.search, ed, buf)
        end
        return true
    elseif action == "find_previous" then
        if #ed.search.results > 0 then
            search.goto_previous(ed.search, ed, buf)
        end
        return true
    elseif action == "move_lines_up" then
        actions.move_lines_up(ed, buf)
        return true
    elseif action == "move_lines_down" then
        actions.move_lines_down(ed, buf)
        return true
    elseif action == "tab_or_indent" then
        actions.tab_or_indent(ed, buf)
        return true
    elseif action == "unindent" then
        actions.unindent(ed, buf)
        return true
    elseif action == "file_start" then
        actions.jump_to_file_start(ed, buf, shift)
        return true
    elseif action == "file_end" then
        actions.jump_to_file_end(ed, buf, shift)
        return true
    elseif action == "word_left" then
        actions.move_word_left(ed, buf, shift)
        return true
    elseif action == "word_right" then
        actions.move_word_right(ed, buf, shift)
        return true
    elseif action == "line_start" then
        actions.jump_to_line_start(ed, buf, shift)
        return true
    elseif action == "line_end" then
        actions.jump_to_line_end(ed, buf, shift)
        return true
    elseif action == "delete_line" then
        actions.delete_line(ed, buf)
        return true
    elseif action == "clear_selection" then
        require("editor").clear_selection(ed)
        return true
    end
    
    return false
end

function keymap.handle_goto_key(key, ed, buf, shift, ctrl, alt)
    if key == "escape" then
        ed.goto_state.active = false
        return true
    elseif key == "return" then
        local goto_module = require("goto")
        goto_module.execute(ed.goto_state, ed, buf)
        return true
    elseif key == "backspace" then
        if #ed.goto_state.input > 0 then
            ed.goto_state.input = ed.goto_state.input:sub(1, -2)
        end
        return true
    end
    return false
end

function keymap.handle_file_dialog_key(key, ed, buf, shift, ctrl, alt)
    if key == "escape" then
        ed.file_dialog.active = false
        return true
    else
        local file_dialog = require("file_dialog")
        return file_dialog.handle_key(ed.file_dialog, key, ed, buf)
    end
end

function keymap.handle_search_key(key, ed, buf, shift, ctrl, alt)
    if key == "escape" then
        search.close(ed.search)
        require("editor").clear_selection(ed)
        return true
    elseif key == "return" or key == "f3" then
        if shift then
            search.goto_previous(ed.search, ed, buf)
        else
            search.goto_next(ed.search, ed, buf)
        end
        return true
    elseif key == "backspace" then
        if #ed.search.query > 0 then
            ed.search.query = ed.search.query:sub(1, -2)
            search.set_query(ed.search, ed.search.query, buf)
        end
        return true
    elseif ctrl then
        if key == "c" then
            search.toggle_case_sensitive(ed.search, buf)
            return true
        elseif key == "w" then
            search.toggle_whole_word(ed.search, buf)
            return true
        end
    end
    return false
end

function keymap.handle_navigation(key, ed, buf, shift, ctrl, alt)
    if key == "return" then
        local undo = require("undo")
        
        if require("editor").has_selection(ed) then
            local selected_text = require("editor").get_selected_text(ed, buf)
            local bounds = require("editor").get_selection_bounds(ed)
            undo.record_deletion(ed.undo_state, bounds.start_line, bounds.start_col, selected_text, ed)
            actions.delete_selection(ed, buf)
        end
        
        undo.record_insertion(ed.undo_state, ed.cursor_line, ed.cursor_col, "\n", ed)
        
        require("buffer").split_line(buf, ed.cursor_line, ed.cursor_col)
        ed.cursor_line = ed.cursor_line + 1
        ed.cursor_col = 0
        require("editor").update_viewport(ed, buf)
        return true
        
    elseif key == "backspace" then
        local undo = require("undo")
        
        if require("editor").has_selection(ed) then
            local selected_text = require("editor").get_selected_text(ed, buf)
            local bounds = require("editor").get_selection_bounds(ed)
            undo.record_deletion(ed.undo_state, bounds.start_line, bounds.start_col, selected_text, ed)
            actions.delete_selection(ed, buf)
        else
            if ed.cursor_col > 0 then
                local line = buf.lines[ed.cursor_line]
                local deleted_char = string.sub(line, ed.cursor_col, ed.cursor_col)
                undo.record_deletion(ed.undo_state, ed.cursor_line, ed.cursor_col - 1, deleted_char, ed)
                
                require("buffer").delete_char(buf, ed.cursor_line, ed.cursor_col)
                ed.cursor_col = ed.cursor_col - 1
            elseif ed.cursor_line > 1 then
                undo.record_deletion(ed.undo_state, ed.cursor_line - 1, #buf.lines[ed.cursor_line - 1], "\n", ed)
                
                ed.cursor_col = require("buffer").join_lines(buf, ed.cursor_line)
                ed.cursor_line = ed.cursor_line - 1
            end
        end
        require("editor").update_viewport(ed, buf)
        return true

    elseif key == "delete" then
        local undo = require("undo")
        
        if require("editor").has_selection(ed) then
            local selected_text = require("editor").get_selected_text(ed, buf)
            local bounds = require("editor").get_selection_bounds(ed)
            undo.record_deletion(ed.undo_state, bounds.start_line, bounds.start_col, selected_text, ed)
            actions.delete_selection(ed, buf)
        else
            local line = buf.lines[ed.cursor_line]
            if ed.cursor_col < #line then
                local deleted_char = string.sub(line, ed.cursor_col + 1, ed.cursor_col + 1)
                undo.record_deletion(ed.undo_state, ed.cursor_line, ed.cursor_col, deleted_char, ed)
                
                require("buffer").delete_char(buf, ed.cursor_line, ed.cursor_col + 1)
            elseif ed.cursor_line < #buf.lines then
                undo.record_deletion(ed.undo_state, ed.cursor_line, ed.cursor_col, "\n", ed)
                
                local next_line = buf.lines[ed.cursor_line + 1]
                buf.lines[ed.cursor_line] = buf.lines[ed.cursor_line] .. next_line
                table.remove(buf.lines, ed.cursor_line + 1)
                require("buffer").mark_dirty(buf)
            end
        end
        require("editor").update_viewport(ed, buf)
        return true

    elseif key == "left" then
        require("editor").move_cursor_left(ed, buf, shift)
        return true
    elseif key == "right" then
        require("editor").move_cursor_right(ed, buf, shift)
        return true
    elseif key == "up" then
        require("editor").move_cursor_up(ed, buf, shift)
        return true
    elseif key == "down" then
        require("editor").move_cursor_down(ed, buf, shift)
        return true
    elseif key == "pageup" then
        require("editor").page_up(ed, buf, shift)
        return true
    elseif key == "pagedown" then
        require("editor").page_down(ed, buf, shift)
        return true
    end
    
    return false
end

function keymap.handle_actions_menu_key(key, ed, buf, shift, ctrl, alt)
    local actions_menu = require("actions_menu")
    return actions_menu.handle_key(ed.actions_menu, key, ed, buf)
end

function keymap.handle_key(key, ed, buf)
    local shift = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
    local ctrl = love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl") 
    local alt = love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt")
    
    if ed.goto_state.active then
        return keymap.handle_goto_key(key, ed, buf, shift, ctrl, alt)
    end
    
    if ed.file_dialog.active then
        return keymap.handle_file_dialog_key(key, ed, buf, shift, ctrl, alt)
    end

    if ed.save_dialog.active then
        return true
    end
    
    if ed.search.active then
        return keymap.handle_search_key(key, ed, buf, shift, ctrl, alt)
    end

    if ed.actions_menu.active then
        return keymap.handle_actions_menu_key(key, ed, buf, shift, ctrl, alt)
    end
    
    local key_string = get_key_string(key, ctrl, shift, alt)
    local action = current_keybinds[key_string]
    
    if action then
        return keymap.execute_action(action, ed, buf, shift, ctrl, alt)
    end
    
    local handled = keymap.handle_navigation(key, ed, buf, shift, ctrl, alt)
    
    if not handled and not ctrl and not alt and key:len() == 1 and key:match("%w") then
        if require("editor").has_selection(ed) then
            actions.delete_selection(ed, buf)
        end
        return false
    end
    
    return handled
end

return keymap