local keymap = {}
local actions = require("actions")

local function is_ctrl_pressed()
    return love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")
end

local function is_shift_pressed()
    return love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
end

local function is_alt_pressed()
    return love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt")
end

function keymap.handle_key(key, ed, buf)
    if is_ctrl_pressed() then
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
        elseif key == "home" then
            actions.jump_to_file_start(ed, buf)
            return true
        elseif key == "end" then
            actions.jump_to_file_end(ed, buf)
            return true
        elseif key == "left" then
            actions.move_word_left(ed, buf)
            return true
        elseif key == "right" then
            actions.move_word_right(ed, buf)
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
        require("buffer").split_line(buf, ed.cursor_line, ed.cursor_col)
        ed.cursor_line = ed.cursor_line + 1
        ed.cursor_col = 0
        require("editor").update_viewport(ed, buf)
        return true
        
    elseif key == "backspace" then
        if ed.cursor_col > 0 then
            require("buffer").delete_char(buf, ed.cursor_line, ed.cursor_col)
            ed.cursor_col = ed.cursor_col - 1
        elseif ed.cursor_line > 1 then
            ed.cursor_col = require("buffer").join_lines(buf, ed.cursor_line)
            ed.cursor_line = ed.cursor_line - 1
        end
        require("editor").update_viewport(ed, buf)
        return true
        
    elseif key == "home" then
        actions.jump_to_line_start(ed, buf)
        return true
    elseif key == "end" then
        actions.jump_to_line_end(ed, buf)
        return true
        
    elseif key == "left" then
        require("editor").move_cursor_left(ed, buf)
        return true
    elseif key == "right" then
        require("editor").move_cursor_right(ed, buf)
        return true
    elseif key == "up" then
        require("editor").move_cursor_up(ed, buf)
        return true
    elseif key == "down" then
        require("editor").move_cursor_down(ed, buf)
        return true
    elseif key == "pageup" then
        require("editor").page_up(ed, buf)
        return true
    elseif key == "pagedown" then
        require("editor").page_down(ed, buf)
        return true
    end
    
    return false  -- Key not handled
end

return keymap