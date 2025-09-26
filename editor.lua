local editor = {}

function editor.create()
    return {
        cursor_line = 1,
        cursor_col = 0,
        selection = {
            active = false,
            start_line = 1,
            start_col = 0,
            end_line = 1,
            end_col = 0
        },
        viewport = {
            top_line = 1,
            left_col = 0,
            target_top_line = 1,
            scroll_animation_time = 0,
            scroll_animation_duration = 0.2
        },
        search = require("search").create(),
        goto_state = require("goto").create(),
        file_dialog = require("file_dialog").create(),
        actions_menu = require("actions_menu").create(),
        undo_state = require("undo").create()
    }
end

function editor.start_selection(ed)
    ed.selection.active = true
    ed.selection.start_line = ed.cursor_line
    ed.selection.start_col = ed.cursor_col
    ed.selection.end_line = ed.cursor_line
    ed.selection.end_col = ed.cursor_col
end

function editor.update_selection(ed)
    if ed.selection.active then
        ed.selection.end_line = ed.cursor_line
        ed.selection.end_col = ed.cursor_col
    end
end

function editor.clear_selection(ed)
    ed.selection.active = false
end

function editor.has_selection(ed)
    return ed.selection.active and 
           (ed.selection.start_line ~= ed.selection.end_line or 
            ed.selection.start_col ~= ed.selection.end_col)
end

function editor.get_selection_bounds(ed)
    if not editor.has_selection(ed) then
        return nil
    end
    
    local start_line, start_col = ed.selection.start_line, ed.selection.start_col
    local end_line, end_col = ed.selection.end_line, ed.selection.end_col
    
    if start_line > end_line or (start_line == end_line and start_col > end_col) then
        start_line, end_line = end_line, start_line
        start_col, end_col = end_col, start_col
    end
    
    return {
        start_line = start_line,
        start_col = start_col,
        end_line = end_line,
        end_col = end_col
    }
end

function editor.get_selected_text(ed, buf)
    local bounds = editor.get_selection_bounds(ed)
    if not bounds then
        return ""
    end
    
    if bounds.start_line == bounds.end_line then
        local line = buf.lines[bounds.start_line]
        return string.sub(line, bounds.start_col + 1, bounds.end_col)
    else
        local result = {}
        for i = bounds.start_line, bounds.end_line do
            local line = buf.lines[i]
            if i == bounds.start_line then
                table.insert(result, string.sub(line, bounds.start_col + 1))
            elseif i == bounds.end_line then
                table.insert(result, string.sub(line, 1, bounds.end_col))
            else
                table.insert(result, line)
            end
        end
        return table.concat(result, "\n")
    end
end

function editor.select_all(ed, buf)
    ed.selection.active = true
    ed.selection.start_line = 1
    ed.selection.start_col = 0
    ed.selection.end_line = #buf.lines
    ed.selection.end_col = #buf.lines[#buf.lines]
end

function editor.select_word(ed, buf)
    local line = buf.lines[ed.cursor_line]
    local start_col = ed.cursor_col
    local end_col = ed.cursor_col
    
    while start_col > 0 and string.match(string.sub(line, start_col, start_col), "%w") do
        start_col = start_col - 1
    end
    while end_col < #line and string.match(string.sub(line, end_col + 1, end_col + 1), "%w") do
        end_col = end_col + 1
    end
    
    ed.selection.active = true
    ed.selection.start_line = ed.cursor_line
    ed.selection.start_col = start_col
    ed.selection.end_line = ed.cursor_line
    ed.selection.end_col = end_col
end

function editor.get_visible_line_count()
    local window_height = love.graphics.getHeight()
    local content_start_y = 60
    local available_height = window_height - content_start_y
    local line_height = get_scaled_line_height()
    return math.floor(available_height / line_height)
end

function editor.get_max_scroll_line(buf)
    local config = require("config")
    local allow_scroll_beyond = config.get("scroll_beyond_last_line")
    local visible_lines = editor.get_visible_line_count()
    
    if allow_scroll_beyond then
        return #buf.lines
    else
        return math.max(1, #buf.lines - visible_lines + 1)
    end
end

function editor.update_viewport(ed, buf)
    local visible_lines = editor.get_visible_line_count()
    local current_target = ed.viewport.target_top_line
    local config = require("config")
    local allow_scroll_beyond = config.get("scroll_beyond_last_line")
    
    local target_top_line = current_target
    
    if ed.cursor_line < current_target then
        target_top_line = ed.cursor_line
    elseif ed.cursor_line >= current_target + visible_lines then
        target_top_line = ed.cursor_line - visible_lines + 1
    end
    
    target_top_line = math.max(1, target_top_line)
    
    local max_line
    if allow_scroll_beyond then
        max_line = #buf.lines
    else
        max_line = math.max(1, #buf.lines - visible_lines + 1)
    end
    
    target_top_line = math.min(target_top_line, max_line)
    
    if target_top_line ~= current_target then
        editor.start_smooth_scroll(ed, target_top_line)
    end
end

function editor.start_smooth_scroll(ed, target_line)
    local config = require("config")
    if not config.get("smooth_scrolling") then
        ed.viewport.top_line = target_line
        ed.viewport.target_top_line = target_line
        ed.viewport.scroll_animation_time = 0
        return
    end
    
    ed.viewport.target_top_line = target_line
    ed.viewport.scroll_animation_time = 0
end

function editor.update_smooth_scroll(ed, dt)
    local config = require("config")
    if not config.get("smooth_scrolling") then
        return
    end
    
    if ed.viewport.top_line ~= ed.viewport.target_top_line then
        ed.viewport.scroll_animation_time = ed.viewport.scroll_animation_time + dt
        
        local progress = ed.viewport.scroll_animation_time / ed.viewport.scroll_animation_duration
        progress = math.min(progress, 1.0)
        
        local eased_progress = 1 - math.pow(1 - progress, 3)
        
        local start_line = ed.viewport.top_line
        local target_line = ed.viewport.target_top_line
        
        if progress >= 1.0 then
            ed.viewport.top_line = target_line
            ed.viewport.scroll_animation_time = 0
        else
            local animated_line = start_line + (target_line - start_line) * eased_progress
            ed.viewport.top_line = math.floor(animated_line + 0.5)
        end
    end
end

function editor.scroll_up(ed, buf, lines)
    lines = lines or 1
    local new_top_line = math.max(1, ed.viewport.top_line - lines)
    
    if new_top_line ~= ed.viewport.top_line then
        editor.start_smooth_scroll(ed, new_top_line)
    end
end

function editor.scroll_down(ed, buf, lines)
    lines = lines or 1
    local config = require("config")
    local allow_scroll_beyond = config.get("scroll_beyond_last_line")
    
    local visible_lines = editor.get_visible_line_count()
    local max_line
    
    if allow_scroll_beyond then
        max_line = #buf.lines
    else
        max_line = math.max(1, #buf.lines - visible_lines + 1)
    end
    
    local new_top_line = math.min(max_line, ed.viewport.top_line + lines)
    
    if new_top_line ~= ed.viewport.top_line then
        editor.start_smooth_scroll(ed, new_top_line)
    end
end

function editor.move_cursor_left(ed, buf, extend_selection)
    if not extend_selection then
        editor.clear_selection(ed)
    elseif not ed.selection.active then
        editor.start_selection(ed)
    end
    
    if ed.cursor_col > 0 then
        ed.cursor_col = ed.cursor_col - 1
    elseif ed.cursor_line > 1 then
        ed.cursor_line = ed.cursor_line - 1
        ed.cursor_col = #buf.lines[ed.cursor_line]
    end
    
    if extend_selection then
        editor.update_selection(ed)
    end
    editor.update_viewport(ed, buf)
end

function editor.move_cursor_right(ed, buf, extend_selection)
    if not extend_selection then
        editor.clear_selection(ed)
    elseif not ed.selection.active then
        editor.start_selection(ed)
    end
    
    local line = buf.lines[ed.cursor_line]
    if ed.cursor_col < #line then
        ed.cursor_col = ed.cursor_col + 1
    elseif ed.cursor_line < #buf.lines then
        ed.cursor_line = ed.cursor_line + 1
        ed.cursor_col = 0
    end
    
    if extend_selection then
        editor.update_selection(ed)
    end
    editor.update_viewport(ed, buf)
end

function editor.move_cursor_up(ed, buf, extend_selection)
    if not extend_selection then
        editor.clear_selection(ed)
    elseif not ed.selection.active then
        editor.start_selection(ed)
    end
    
    if ed.cursor_line > 1 then
        ed.cursor_line = ed.cursor_line - 1
        local line = buf.lines[ed.cursor_line]
        ed.cursor_col = math.min(ed.cursor_col, #line)
    end
    
    if extend_selection then
        editor.update_selection(ed)
    end
    editor.update_viewport(ed, buf)
end

function editor.move_cursor_down(ed, buf, extend_selection)
    if not extend_selection then
        editor.clear_selection(ed)
    elseif not ed.selection.active then
        editor.start_selection(ed)
    end
    
    if ed.cursor_line < #buf.lines then
        ed.cursor_line = ed.cursor_line + 1
        local line = buf.lines[ed.cursor_line]
        ed.cursor_col = math.min(ed.cursor_col, #line)
    end
    
    if extend_selection then
        editor.update_selection(ed)
    end
    editor.update_viewport(ed, buf)
end

function editor.page_up(ed, buf, extend_selection)
    if not extend_selection then
        editor.clear_selection(ed)
    elseif not ed.selection.active then
        editor.start_selection(ed)
    end
    
    local visible_lines = editor.get_visible_line_count()
    ed.cursor_line = math.max(1, ed.cursor_line - visible_lines)
    local line = buf.lines[ed.cursor_line]
    ed.cursor_col = math.min(ed.cursor_col, #line)
    
    if extend_selection then
        editor.update_selection(ed)
    end
    editor.update_viewport(ed, buf)
end

function editor.page_down(ed, buf, extend_selection)
    if not extend_selection then
        editor.clear_selection(ed)
    elseif not ed.selection.active then
        editor.start_selection(ed)
    end
    
    local visible_lines = editor.get_visible_line_count()
    local max_line = editor.get_max_scroll_line(buf)
    local new_top_line = math.min(max_line, ed.viewport.top_line + visible_lines)
    
    local cursor_offset = ed.cursor_line - ed.viewport.top_line
    ed.cursor_line = math.min(#buf.lines, new_top_line + cursor_offset)
    local line = buf.lines[ed.cursor_line]
    ed.cursor_col = math.min(ed.cursor_col, #line)
    
    if extend_selection then
        editor.update_selection(ed)
    end
    
    editor.start_smooth_scroll(ed, new_top_line)
end

return editor