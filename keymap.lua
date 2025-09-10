local keymap = {}
local actions = require("actions")

local function is_ctrl_pressed()
    return love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")
end

local function is_shift_pressed()
    return love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
end

function keymap.handle_key(key, ed, buf)
    local shift = is_shift_pressed()
    local ctrl = is_ctrl_pressed()
    
    if not ctrl and key:len() == 1 and key:match("%w") then
        if require("editor").has_selection(ed) then
            actions.delete_selection(ed, buf)
        end
        return false
    end
    
    if ctrl then
        if key == "s" then
            require("buffer").save_file(buf)
            return true
        elseif key == "c" then
            actions.copy(ed, buf)
            return true
        elseif key == "v" then
            actions.paste(ed, buf)
            return true
        elseif key == "x" then
            actions.cut(ed, buf)
            return true
        elseif key == "a" then
            actions.select_all(ed, buf)
            return true
        elseif key == "d" then
            actions.select_word(ed, buf)
            return true
        elseif key == "home" then
            actions.jump_to_file_start(ed, buf, shift)
            return true
        elseif key == "end" then
            actions.jump_to_file_end(ed, buf, shift)
            return true
        elseif key == "left" then
            actions.move_word_left(ed, buf, shift)
            return true
        elseif key == "right" then
            actions.move_word_right(ed, buf, shift)
            return true
        elseif key == "k" then
            actions.delete_to_line_end(ed, buf)
            return true
        elseif key == "u" then
            actions.delete_to_line_start(ed, buf)
            return true
        end
    end
    
    if key == "return" then
        if require("editor").has_selection(ed) then
            actions.delete_selection(ed, buf)
        end
        require("buffer").split_line(buf, ed.cursor_line, ed.cursor_col)
        ed.cursor_line = ed.cursor_line + 1
        ed.cursor_col = 0
        require("editor").update_viewport(ed, buf)
        return true
        
    elseif key == "backspace" then
        if require("editor").has_selection(ed) then
            actions.delete_selection(ed, buf)
        else
            if ed.cursor_col > 0 then
                require("buffer").delete_char(buf, ed.cursor_line, ed.cursor_col)
                ed.cursor_col = ed.cursor_col - 1
            elseif ed.cursor_line > 1 then
                ed.cursor_col = require("buffer").join_lines(buf, ed.cursor_line)
                ed.cursor_line = ed.cursor_line - 1
            end
        end
        require("editor").update_viewport(ed, buf)
        return true
        
    elseif key == "delete" then
        if require("editor").has_selection(ed) then
            actions.delete_selection(ed, buf)
        else
            local line = buf.lines[ed.cursor_line]
            if ed.cursor_col < #line then
                require("buffer").delete_char(buf, ed.cursor_line, ed.cursor_col + 1)
            elseif ed.cursor_line < #buf.lines then
                local next_line = buf.lines[ed.cursor_line + 1]
                buf.lines[ed.cursor_line] = buf.lines[ed.cursor_line] .. next_line
                table.remove(buf.lines, ed.cursor_line + 1)
                require("buffer").mark_dirty(buf)
            end
        end
        require("editor").update_viewport(ed, buf)
        return true
        
    elseif key == "home" then
        actions.jump_to_line_start(ed, buf, shift)
        return true
    elseif key == "end" then
        actions.jump_to_line_end(ed, buf, shift)
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
    elseif key == "escape" then
        require("editor").clear_selection(ed)
        return true
    end
    
    return false
end

return keymap