local love = require("love")
local buffer = require("buffer")
local editor = require("editor")
local keymap = require("keymap")
local search = require("search")
local langs = require("langs.init")
local colors = require("colors") 
local syntax = require("syntax")
local color_preview = require("color_preview")
local welcome = require("welcome")

local current_buffer
local current_editor

local file_check_timer = 0
local file_check_interval = 1.0

local cursor_visible = true
local cursor_blink_start_time = 0
local CURSOR_BLINK_SPEED = 0.5

local paste_animations = {}
local PASTE_ANIMATION_SPEED = 1.0

function love.load(args)
    local config = require("config")
    config.load()

    local version = require("version")
    version.load()

    local font_name = config.get("font")
    local font_size = config.get("font_size") or 14
    
    if font_name and font_name ~= "default" then
        local success, font = pcall(love.graphics.newFont, font_name, font_size)
        if success then
            love.graphics.setFont(font)
        else
            print("Could not load font: " .. font_name .. ", using default")
        end
    else
        love.graphics.setFont(love.graphics.newFont(font_size))
    end

    local colors = require("colors")
    colors.load()

    local keymap = require("keymap")
    keymap.load_keybinds()

    love.window.setTitle("Natura Editor")

    local icon_success, icon_data = pcall(love.image.newImageData, "extras/assets/logo.png")
    if icon_success then
        love.window.setIcon(icon_data)
    end

    local window_width = config.get("window_width")
    local window_height = config.get("window_height")

    local display_index = 1
    
    if config.get("open_on_the_biggest_monitor") then
        local display_count = love.window.getDisplayCount()
        local biggest_area = 0
        
        for i = 1, display_count do
            local width, height = love.window.getDesktopDimensions(i)
            local area = width * height
            if area > biggest_area then
                biggest_area = area
                display_index = i
            end
        end
    end
    
    love.window.setMode(window_width, window_height, {
        resizable = true,
        minwidth = 400,
        minheight = 300,
        display = display_index
    })

    if config.get("maximize_on_start") then
        love.window.maximize()
    end
    
    love.keyboard.setKeyRepeat(true)
    
    current_buffer = buffer.create()
    current_editor = editor.create()

    _G.current_buffer = current_buffer
    
    if args and args[1] then
        local filepath = args[1]
        if love.filesystem.getInfo(filepath) then
            buffer.load_file(current_buffer, filepath)
        else
            local filename = filepath:match("([^/\\]+)$") or filepath
            if love.filesystem.getInfo(filename) then
                buffer.load_file(current_buffer, filename)
            else
                print("Could not find file: " .. filepath)
            end
        end
    end
    
    print("Natura Editor starting...")
end

function love.filedropped(file)
    local filename = file:getFilename()
    if filename:match("%.config$") then
        local config = require("config")
        config.reload()
        
        local colors = require("colors")
        colors.reload()
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    local color_preview = require("color_preview")
    if color_preview.handle_mouse_pressed(x, y, button) then
        return
    end
    
    if not welcome.is_showing() then
        local scrollbar = require("scrollbar")
        local content_area = {
            x = 0,
            y = 40, -- content_start_y
            w = love.graphics.getWidth(),
            h = love.graphics.getHeight() - 40
        }
        if scrollbar.handle_mouse_pressed(x, y, button, current_editor, current_buffer, content_area) then
            return
        end
    end
    
    local mouse = require("mouse")
    mouse.handle_press(current_editor, current_buffer, x, y, button)
end

function love.mousemoved(x, y, dx, dy, istouch)
    local color_preview = require("color_preview")
    color_preview.handle_mouse_moved(x, y)
    
    if not welcome.is_showing() then
        local scrollbar = require("scrollbar")
        local content_area = {
            x = 0,
            y = 40, -- content_start_y
            w = love.graphics.getWidth(),
            h = love.graphics.getHeight() - 40
        }
        if scrollbar.handle_mouse_moved(x, y, current_editor, current_buffer, content_area) then
            return
        end
    end
    
    local mouse = require("mouse")
    mouse.handle_drag(current_editor, current_buffer, x, y, dx, dy)
end

function love.mousereleased(x, y, button, istouch, presses)
    local color_preview = require("color_preview")
    color_preview.handle_mouse_released(x, y, button)
    
    local scrollbar = require("scrollbar")
    if scrollbar.handle_mouse_released(x, y, button) then
        return
    end
    
    local mouse = require("mouse")
    mouse.handle_release(current_editor, current_buffer, x, y, button)
end

function love.textinput(text)
    cursor_blink_start_time = love.timer.getTime()
    cursor_visible = true
    
    if current_editor.file_dialog.active then
        local file_dialog = require("file_dialog")
        file_dialog.handle_text(current_editor.file_dialog, text)
        return
    end
    
    if current_editor.save_dialog.active then
        local save_dialog = require("save_dialog")
        save_dialog.handle_text(current_editor.save_dialog, text)
        return
    end
    
    if current_editor.goto_state.active then
        local goto_module = require("goto")
        goto_module.handle_input(current_editor.goto_state, text)
        return
    end
    
    if current_editor.search.active then
        current_editor.search.query = current_editor.search.query .. text
        search.set_query(current_editor.search, current_editor.search.query, current_buffer)
        return
    end
    
    if current_editor.actions_menu.active then
        local actions_menu = require("actions_menu")
        actions_menu.handle_text(current_editor.actions_menu, text)
        return
    end
    
    local undo = require("undo")
    local actions = require("actions")
    
    if editor.has_selection(current_editor) then
        local selected_text = editor.get_selected_text(current_editor, current_buffer)
        local bounds = editor.get_selection_bounds(current_editor)
        undo.record_deletion(current_editor.undo_state, bounds.start_line, bounds.start_col, selected_text, current_editor)
        actions.delete_selection(current_editor, current_buffer)
    end
    
    undo.record_insertion(current_editor.undo_state, current_editor.cursor_line, current_editor.cursor_col, text, current_editor)
    
    current_editor.cursor_col = buffer.insert_text(current_buffer, current_editor.cursor_line, current_editor.cursor_col, text)
    editor.update_viewport(current_editor, current_buffer)
end

function love.keypressed(key)
    cursor_blink_start_time = love.timer.getTime()
    cursor_visible = true
    
    if current_editor.goto_state.active then
        local goto_module = require("goto")
        if goto_module.handle_key(current_editor.goto_state, key, current_editor, current_buffer) then
            return
        end
    end

    if current_editor.save_dialog.active then
        local save_dialog = require("save_dialog")
        if save_dialog.handle_key(current_editor.save_dialog, key) then
            return
        end
    end
    
    if not keymap.handle_key(key, current_editor, current_buffer) then
        print("Unhandled key: " .. key)
    end

    if color_preview.handle_key(key) then
        return
    end
end

function love.wheelmoved(x, y)
    if y > 0 then
        editor.scroll_up(current_editor, current_buffer, 3)
    elseif y < 0 then
        editor.scroll_down(current_editor, current_buffer, 3)
    end
    
    local scrollbar = require("scrollbar")
    scrollbar.start_fade_out_animation("main_scrollbar")
end

function love.update(dt)
    file_check_timer = file_check_timer + dt

    editor.update_smooth_scroll(current_editor, dt)

    update_paste_animations(dt)

    local config = require("config")
    local blink_time = config.get("cursor_blink_time_in_seconds") or 5
    
    if type(blink_time) == "string" then
        blink_time = tonumber(blink_time) or 5
    end
    
    if blink_time > 0 then
        local time_since_blink_start = love.timer.getTime() - cursor_blink_start_time
        
        if time_since_blink_start > blink_time then
            cursor_visible = true
        else
            cursor_visible = math.floor(time_since_blink_start / CURSOR_BLINK_SPEED) % 2 == 0
        end
    else
        cursor_visible = true
    end

    if file_check_timer >= file_check_interval then
        file_check_timer = 0
        
        local is_config_file = current_buffer.filepath and current_buffer.filepath:match("natura%.config$")
        
        if not is_config_file and buffer.check_external_modification(current_buffer) then
            print("File modified externally, reloading: " .. current_buffer.filepath)
            buffer.reload_from_disk(current_buffer)
            
            current_editor.cursor_line = math.min(current_editor.cursor_line, #current_buffer.lines)
            current_editor.cursor_col = math.min(current_editor.cursor_col, #current_buffer.lines[current_editor.cursor_line])
            editor.clear_selection(current_editor)
            editor.update_viewport(current_editor, current_buffer)
        end
    end

    local undo = require("undo")
    if current_editor.undo_state.current_group then
        local time_since_last = love.timer.getTime() - current_editor.undo_state.last_action_time
        if time_since_last > 1.0 then
            undo.finish_edit_group(current_editor.undo_state, current_editor)
        end
    end

    color_preview.update(current_editor, current_buffer)
end

local function draw_selection_highlight(ed, font, line_height, content_start_y)
    if not editor.has_selection(ed) then
        return
    end
    
    local bounds = editor.get_selection_bounds(ed)
    if not bounds then return end
    
    love.graphics.setColor(0.3, 0.4, 0.6, 0.3)
    
    local visible_lines = editor.get_visible_line_count()
    local viewport_start = ed.viewport.top_line
    local viewport_end = viewport_start + visible_lines - 1
    
    for line_num = math.max(bounds.start_line, viewport_start), math.min(bounds.end_line, viewport_end) do
        local y = content_start_y + (line_num - viewport_start) * line_height
        local line = current_buffer.lines[line_num]
        
        local start_col, end_col
        if line_num == bounds.start_line and line_num == bounds.end_line then
            start_col, end_col = bounds.start_col, bounds.end_col
        elseif line_num == bounds.start_line then
            start_col, end_col = bounds.start_col, #line
        elseif line_num == bounds.end_line then
            start_col, end_col = 0, bounds.end_col
        else
            start_col, end_col = 0, #line
        end
        
        local start_text = string.sub(line, 1, start_col)
        local selected_text = string.sub(line, start_col + 1, end_col)
        
        local start_x = 10 + font:getWidth(start_text)
        local width = font:getWidth(selected_text)
        
        if width < 3 then width = 3 end
        
        love.graphics.rectangle("fill", start_x, y, width, line_height)
    end
end

function find_selection_occurrences(ed, buf)
    if not editor.has_selection(ed) then
        return {}
    end
    
    local config = require("config")
    if not config.get("highlight_selection_occurrences") then
        return {}
    end
    
    local bounds = editor.get_selection_bounds(ed)
    if not bounds then return {} end
    
    local selected_text = ""
    if bounds.start_line == bounds.end_line then
        local line = buf.lines[bounds.start_line]
        selected_text = line:sub(bounds.start_col + 1, bounds.end_col)
    else
        return {}
    end
    
    if selected_text == "" or selected_text:match("^%s*$") then
        return {}
    end
    
    local occurrences = {}
    for line_num = 1, #buf.lines do
        local line = buf.lines[line_num]
        local start_pos = 1
        
        while true do
            local found_start, found_end = line:find(selected_text, start_pos, true)
            if not found_start then
                break
            end
            
            if not (line_num == bounds.start_line and found_start == bounds.start_col + 1) then
                table.insert(occurrences, {
                    line = line_num,
                    start_col = found_start - 1,
                    end_col = found_end
                })
            end
            
            start_pos = found_start + 1
        end
    end
    
    return occurrences
end

function draw_selection_occurrences(ed, buf, font, line_height, content_start_y, text_start_x)
    local occurrences = find_selection_occurrences(ed, buf)
    if #occurrences == 0 then
        return
    end
    
    local colors = require("colors")
    colors.set_color("selection_highlight")
    
    local visible_lines = editor.get_visible_line_count()
    local viewport_start = ed.viewport.top_line
    local viewport_end = viewport_start + visible_lines - 1
    
    for _, occurrence in ipairs(occurrences) do
        if occurrence.line >= viewport_start and occurrence.line <= viewport_end then
            local y = content_start_y + (occurrence.line - viewport_start) * line_height
            local line = buf.lines[occurrence.line]
            
            local before_text = line:sub(1, occurrence.start_col)
            local occurrence_text = line:sub(occurrence.start_col + 1, occurrence.end_col)
            
            local x = text_start_x + font:getWidth(before_text)
            local width = font:getWidth(occurrence_text)
            
            love.graphics.rectangle("fill", x, y, width, line_height)
        end
    end
end

function draw_line_highlight(ed, buf, font, line_height, content_start_y, text_start_x)
    local config = require("config")
    if not config.get("highlight_line_with_cursor") then
        return
    end
    
    if editor.has_selection(ed) then
        return
    end
    
    local visible_lines = editor.get_visible_line_count()
    if ed.cursor_line < ed.viewport.top_line or ed.cursor_line > ed.viewport.top_line + visible_lines - 1 then
        return
    end
    
    local colors = require("colors")
    colors.set_color("line_highlight")
    
    local cursor_y = content_start_y + (ed.cursor_line - ed.viewport.top_line) * line_height
    local editor_area = get_editor_content_area()
    
    love.graphics.rectangle("fill", editor_area.x, cursor_y, editor_area.width, line_height)
end

local function draw_search_bar(ed)
    if not ed.search.active then return end
    
    local window_width = love.graphics.getWidth()
    local bar_width = 300
    local bar_height = 25
    local bar_x = window_width - bar_width - 10
    local bar_y = 10
    
    love.graphics.setColor(0.2, 0.2, 0.2, 0.9)
    love.graphics.rectangle("fill", bar_x, bar_y, bar_width, bar_height)
    
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.rectangle("line", bar_x, bar_y, bar_width, bar_height)
    
    love.graphics.setColor(1, 1, 1)
    local search_text = "Find: " .. ed.search.query
    if #ed.search.results > 0 then
        search_text = search_text .. string.format(" (%d/%d)", ed.search.current_result, #ed.search.results)
    else
        search_text = search_text .. " (0 results)"
    end
    
    local modes = {}
    if ed.search.case_sensitive then table.insert(modes, "Aa") end
    if ed.search.whole_word then table.insert(modes, "\\b") end
    if #modes > 0 then
        search_text = search_text .. " [" .. table.concat(modes, " ") .. "]"
    end
    
    local font = love.graphics.getFont()
    local available_width = bar_width - 10
    local text_width = font:getWidth(search_text)
    
    if text_width > available_width then
        while font:getWidth(search_text .. "...") > available_width and #search_text > 0 do
            search_text = search_text:sub(1, -2)
        end
        search_text = search_text .. "..."
    end
    
    love.graphics.print(search_text, bar_x + 5, bar_y + 5)
end

function draw_search_highlights(ed, font, line_height, content_start_y, text_start_x)
    local colors = require("colors")
    
    if not ed.search.active or #ed.search.results == 0 then
        return
    end
    
    for i, result in ipairs(ed.search.results) do
        if result.line >= ed.viewport.top_line and result.line <= ed.viewport.top_line + editor.get_visible_line_count() - 1 then
            local y = content_start_y + (result.line - ed.viewport.top_line) * line_height
            local line = current_buffer.lines[result.line]
            local before_match = line:sub(1, result.start_col)
            local match_text = line:sub(result.start_col + 1, result.end_col)
            
            local x = text_start_x + font:getWidth(before_match)
            local width = font:getWidth(match_text)
            
            if i == ed.search.current_result then
                colors.set_color("search_result_active")
            else
                colors.set_color("search_result_inactive")
            end
            
            love.graphics.rectangle("fill", x, y, width, line_height)
        end
    end
end

function draw_selection_highlight(ed, font, line_height, content_start_y, text_start_x)
    local colors = require("colors")
    
    if not editor.has_selection(ed) then
        return
    end
    
    local bounds = editor.get_selection_bounds(ed)
    
    for line_num = bounds.start_line, bounds.end_line do
        if line_num >= ed.viewport.top_line and line_num <= ed.viewport.top_line + editor.get_visible_line_count() - 1 then
            local y = content_start_y + (line_num - ed.viewport.top_line) * line_height
            local line = current_buffer.lines[line_num]
            
            local start_col = (line_num == bounds.start_line) and bounds.start_col or 0
            local end_col = (line_num == bounds.end_line) and bounds.end_col or #line
            
            local before_selection = line:sub(1, start_col)
            local selection_text = line:sub(start_col + 1, end_col)
            
            local x = text_start_x + font:getWidth(before_selection)
            local width = font:getWidth(selection_text)
            
            colors.set_color("selection_active")
            love.graphics.rectangle("fill", x, y, width, line_height)
        end
    end
end

function draw_line_with_syntax_highlighting(line, x, y, line_num, language)
    if not language then
        colors.set_color("code_default")
        love.graphics.print(line, x, y)
        return
    end
    
    local tokens = syntax.get_line_tokens(current_buffer, line_num)
    
    if #tokens == 0 then
        colors.set_color("code_default") 
        love.graphics.print(line, x, y)
        return
    end
    
    local current_x = x
    local last_end = 1
    
    for _, token in ipairs(tokens) do
        if token.start > last_end then
            local before_text = line:sub(last_end, token.start - 1)
            colors.set_color("code_default")
            love.graphics.print(before_text, current_x, y)
            current_x = current_x + love.graphics.getFont():getWidth(before_text)
        end
        
        local token_text = line:sub(token.start, token.start + token.length - 1)
        local color_name = get_color_for_token_type(token.type)
        colors.set_color(color_name)
        love.graphics.print(token_text, current_x, y)
        current_x = current_x + love.graphics.getFont():getWidth(token_text)
        
        last_end = token.start + token.length
    end
    
    if last_end <= #line then
        local remaining_text = line:sub(last_end)
        colors.set_color("code_default")
        love.graphics.print(remaining_text, current_x, y)
    end
end

function is_bracket(char)
    return char == "(" or char == ")" or char == "[" or char == "]" or char == "{" or char == "}"
end

function get_matching_bracket(bracket)
    local pairs = {
        ["("] = ")",
        [")"] = "(",
        ["["] = "]",
        ["]"] = "[",
        ["{"] = "}",
        ["}"] = "{"
    }
    return pairs[bracket]
end

function is_opening_bracket(bracket)
    return bracket == "(" or bracket == "[" or bracket == "{"
end

function find_matching_bracket(buf, line, col)
    if line < 1 or line > #buf.lines then
        return nil
    end
    
    local current_line = buf.lines[line]
    if col < 0 or col >= #current_line then
        return nil
    end
    
    local bracket = current_line:sub(col + 1, col + 1)
    if not is_bracket(bracket) then
        return nil
    end
    
    local matching_bracket = get_matching_bracket(bracket)
    local is_opening = is_opening_bracket(bracket)
    local stack_count = 1
    
    if is_opening then
        local search_col = col + 1
        local search_line = line
        
        while search_line <= #buf.lines do
            local line_text = buf.lines[search_line]
            local start_col = (search_line == line) and search_col + 1 or 1
            
            for i = start_col, #line_text do
                local char = line_text:sub(i, i)
                if char == bracket then
                    stack_count = stack_count + 1
                elseif char == matching_bracket then
                    stack_count = stack_count - 1
                    if stack_count == 0 then
                        return {line = search_line, col = i - 1}
                    end
                end
            end
            search_line = search_line + 1
        end
    else
        local search_col = col - 1
        local search_line = line
        
        while search_line >= 1 do
            local line_text = buf.lines[search_line]
            local end_col = (search_line == line) and search_col + 1 or #line_text
            
            for i = end_col, 1, -1 do
                local char = line_text:sub(i, i)
                if char == bracket then
                    stack_count = stack_count + 1
                elseif char == matching_bracket then
                    stack_count = stack_count - 1
                    if stack_count == 0 then
                        return {line = search_line, col = i - 1}
                    end
                end
            end
            search_line = search_line - 1
        end
    end
    
    return nil
end

function draw_bracket_highlights(ed, buf, font, line_height, content_start_y, text_start_x)
    local config = require("config")
    if not config.get("highlight_matching_brackets") then
        return
    end
    
    local cursor_line = ed.cursor_line
    local cursor_col = ed.cursor_col
    local line_text = buf.lines[cursor_line]
    
    local brackets_to_highlight = {}
    
    if cursor_col < #line_text then
        local char_at_cursor = line_text:sub(cursor_col + 1, cursor_col + 1)
        if is_bracket(char_at_cursor) then
            local match = find_matching_bracket(buf, cursor_line, cursor_col)
            if match then
                table.insert(brackets_to_highlight, {line = cursor_line, col = cursor_col})
                table.insert(brackets_to_highlight, match)
            end
        end
    end
    
    if cursor_col > 0 then
        local char_before_cursor = line_text:sub(cursor_col, cursor_col)
        if is_bracket(char_before_cursor) then
            local match = find_matching_bracket(buf, cursor_line, cursor_col - 1)
            if match then
                table.insert(brackets_to_highlight, {line = cursor_line, col = cursor_col - 1})
                table.insert(brackets_to_highlight, match)
            end
        end
    end

    if #brackets_to_highlight > 0 then
        local colors = require("colors")
        colors.set_color("bracket_highlight")
        
        local visible_lines = editor.get_visible_line_count()
        local viewport_start = ed.viewport.top_line
        local viewport_end = viewport_start + visible_lines - 1
        
        for _, bracket in ipairs(brackets_to_highlight) do
            if bracket.line >= viewport_start and bracket.line <= viewport_end then
                local y = content_start_y + (bracket.line - viewport_start) * line_height
                local bracket_line = buf.lines[bracket.line]
                local before_bracket = bracket_line:sub(1, bracket.col)
                local bracket_char = bracket_line:sub(bracket.col + 1, bracket.col + 1)
                
                local x = text_start_x + font:getWidth(before_bracket)
                local width = font:getWidth(bracket_char)
                
                love.graphics.rectangle("fill", x, y, width, line_height)
            end
        end
    end
end

function add_paste_animation(start_line, start_col, end_line, end_col)
    local config = require("config")
    if not config.get("show_paste_effect") then
        return
    end
    
    local animation = {
        start_line = start_line,
        start_col = start_col,
        end_line = end_line,
        end_col = end_col,
        start_time = love.timer.getTime()
    }
    
    table.insert(paste_animations, animation)
end

function update_paste_animations(dt)
    local current_time = love.timer.getTime()
    
    for i = #paste_animations, 1, -1 do
        local anim = paste_animations[i]
        local elapsed = current_time - anim.start_time
        
        if elapsed >= PASTE_ANIMATION_SPEED then
            table.remove(paste_animations, i)
        end
    end
end

function draw_paste_animations(ed, buf, font, line_height, content_start_y, text_start_x)
    if #paste_animations == 0 then
        return
    end
    
    local colors = require("colors")
    local current_time = love.timer.getTime()
    local visible_lines = editor.get_visible_line_count()
    local viewport_start = ed.viewport.top_line
    local viewport_end = viewport_start + visible_lines - 1
    
    for _, anim in ipairs(paste_animations) do
        local elapsed = current_time - anim.start_time
        if elapsed < PASTE_ANIMATION_SPEED then
            local alpha = 1.0 - (elapsed / PASTE_ANIMATION_SPEED)
            
            for line_num = anim.start_line, anim.end_line do
                if line_num >= viewport_start and line_num <= viewport_end then
                    local y = content_start_y + (line_num - viewport_start) * line_height
                    local line_text = buf.lines[line_num]
                    
                    local start_col, end_col
                    if line_num == anim.start_line and line_num == anim.end_line then
                        start_col, end_col = anim.start_col, anim.end_col
                    elseif line_num == anim.start_line then
                        start_col, end_col = anim.start_col, #line_text
                    elseif line_num == anim.end_line then
                        start_col, end_col = 0, anim.end_col
                    else
                        start_col, end_col = 0, #line_text
                    end
                    
                    local before_text = line_text:sub(1, start_col)
                    local highlighted_text = line_text:sub(start_col + 1, end_col)
                    
                    local x = text_start_x + font:getWidth(before_text)
                    local width = font:getWidth(highlighted_text)
                    
                    local paste_color = colors.get("paste_animation")
                    love.graphics.setColor(paste_color[1], paste_color[2], paste_color[3], paste_color[4] * alpha)
                    love.graphics.rectangle("fill", x, y, width, line_height)
                end
            end
        end
    end
end

function get_color_for_token_type(token_type)
    local color_map = {
        ["keyword"] = "code_keyword",
        ["string_literal"] = "code_string_literal",
        ["comment"] = "code_comment",
        ["function"] = "code_function", 
        ["number"] = "code_number",
        ["identifier"] = "code_identifier",
        ["punctuation"] = "code_punctuation",
        ["operation"] = "code_operation",
        ["default"] = "code_default",
        
        ["section_header"] = "config_section_header",
        ["color_key"] = "config_color_key", 
        ["keybind_key"] = "config_keybind_key",
        ["setting_key"] = "config_setting_key",
        ["separator"] = "config_separator",
        ["hex_value"] = "config_hex_value",
        ["action_value"] = "config_action_value",
        ["string_value"] = "config_string_value", 
        ["number_value"] = "config_number_value"
    }
    return color_map[token_type] or "code_default"
end

function get_scaled_line_height()
    local font = love.graphics.getFont()
    local base_height = font:getHeight()
    local config = require("config")
    local scale_percent = config.get("line_height_scale_percent") or 120
    
    return math.floor(base_height * (scale_percent / 100) + 0.5)
end

function get_editor_content_area()
    local config = require("config")
    local max_width = config.get("max_editor_width") or -1
    local window_width = love.graphics.getWidth()
    
    if max_width <= 0 then
        return {
            x = 10,
            width = window_width - 20,
            content_x = 10
        }
    else
        local content_width = math.min(max_width, window_width - 40)
        local content_x = (window_width - content_width) / 2
        
        return {
            x = content_x,
            width = content_width,
            content_x = content_x
        }
    end
end

function get_line_number_gutter_width(buf)
    local config = require("config")
    if not config.get("show_line_numbers") then
        return 0
    end
    
    local font = love.graphics.getFont()
    local max_line = #buf.lines
    local max_digits = string.len(tostring(max_line))
    local digit_width = font:getWidth("0")
    local padding = 10
    
    return max_digits * digit_width + padding
end

function get_text_start_x()
    local editor_area = get_editor_content_area()
    local gutter_width = get_line_number_gutter_width(current_buffer)
    
    return editor_area.content_x + gutter_width
end

function draw_line_numbers(ed, buf, font, line_height, content_start_y)
    local config = require("config")
    if not config.get("show_line_numbers") then
        return
    end
    
    local gutter_width = get_line_number_gutter_width(buf)
    if gutter_width == 0 then return end
    
    local colors = require("colors")
    local editor_area = get_editor_content_area()
    local gutter_x = editor_area.x
    
    colors.set_color("background_dark")
    love.graphics.rectangle("fill", gutter_x, content_start_y, gutter_width, love.graphics.getHeight() - content_start_y)
    
    colors.set_color("text_dim")
    love.graphics.line(gutter_x + gutter_width - 1, content_start_y, gutter_x + gutter_width - 1, love.graphics.getHeight())
    
    colors.set_color("text_dim")
    local visible_lines = editor.get_visible_line_count()
    local end_line = math.min(#buf.lines, ed.viewport.top_line + visible_lines - 1)
    
    for i = ed.viewport.top_line, end_line do
        local y = content_start_y + (i - ed.viewport.top_line) * line_height
        local line_num_text = tostring(i)
        local text_width = font:getWidth(line_num_text)
        
        local x = gutter_x + gutter_width - text_width - 5
        
        if i == ed.cursor_line then
            colors.set_color("text")
        else
            colors.set_color("text_dim")
        end
        
        love.graphics.print(line_num_text, x, y)
    end
end

function love.draw()    
    local bg_color = colors.get("background")
    love.graphics.clear(bg_color[1], bg_color[2], bg_color[3], bg_color[4])
    
    local any_dialog_active = current_editor.file_dialog.active or 
                            current_editor.actions_menu.active or
                            current_editor.search.active or
                            current_editor.goto_state.active

    local save_dialog = require("save_dialog")
    save_dialog.draw(current_editor.save_dialog)

    if welcome.is_showing() and not any_dialog_active then
        welcome.draw()
        return
    end

    if welcome.is_showing() and any_dialog_active then
        welcome.draw()
    end

    local title = "Natura Editor"
    colors.set_color("text")
    if current_buffer.filepath then
        title = title .. " - " .. current_buffer.filepath
        if current_buffer.dirty then
            title = title .. " *"
        end
    end

    if not welcome.is_showing() then
        love.graphics.print(title, 10, 10)
    end

    colors.set_color("ui_success")

    local debug_lang = "" .. (current_buffer.language or "None")

    if not welcome.is_showing() then
        love.graphics.print(debug_lang, love.graphics.getWidth() - 50, 10)
    end
    
    local font = love.graphics.getFont()
    local line_height = get_scaled_line_height()
    local content_start_y = 40
    local text_start_x = get_text_start_x()

    if not welcome.is_showing() then
        draw_line_numbers(current_editor, current_buffer, font, line_height, content_start_y)
    end
    
    draw_search_highlights(current_editor, font, line_height, content_start_y, text_start_x)
    draw_selection_highlight(current_editor, font, line_height, content_start_y, text_start_x)
    draw_selection_occurrences(current_editor, current_buffer, font, line_height, content_start_y, text_start_x)
    draw_line_highlight(current_editor, current_buffer, font, line_height, content_start_y, text_start_x)
    draw_bracket_highlights(current_editor, current_buffer, font, line_height, content_start_y, text_start_x)
    draw_paste_animations(current_editor, current_buffer, font, line_height, content_start_y, text_start_x)
    
    colors.set_color("code_default")
    
    local visible_lines = editor.get_visible_line_count()
    local end_line = math.min(#current_buffer.lines, current_editor.viewport.top_line + visible_lines - 1)

    for i = current_editor.viewport.top_line, end_line do
        local line = current_buffer.lines[i]
        local y = content_start_y + (i - current_editor.viewport.top_line) * line_height
        
        draw_line_with_syntax_highlighting(line, text_start_x, y, i, current_buffer.language)
    end
    
    if not welcome.is_showing() then
        if current_editor.cursor_line >= current_editor.viewport.top_line and 
        current_editor.cursor_line <= current_editor.viewport.top_line + visible_lines - 1 then
            local cursor_y = content_start_y + (current_editor.cursor_line - current_editor.viewport.top_line) * line_height
            local cursor_text = string.sub(current_buffer.lines[current_editor.cursor_line], 1, current_editor.cursor_col)
            local cursor_x = text_start_x + font:getWidth(cursor_text)
            
            if cursor_visible then
                local config = require("config")
                local cursor_as_block = config.get("cursor_as_block")
                
                colors.set_color("cursor")
                if cursor_as_block then
                    local char_width = font:getWidth(" ")
                    local radius = config.get("cursor_corner_radius") or 3
                    
                    love.graphics.rectangle("fill", cursor_x, cursor_y, char_width, line_height, radius, radius)
                    
                    local char_under_cursor = string.sub(current_buffer.lines[current_editor.cursor_line], current_editor.cursor_col + 1, current_editor.cursor_col + 1)
                    if char_under_cursor ~= "" then
                        colors.set_color("background")
                        love.graphics.print(char_under_cursor, cursor_x, cursor_y)
                    end
                else
                    love.graphics.line(cursor_x, cursor_y, cursor_x, cursor_y + line_height)
                end
            end
        end
    end
    draw_search_bar(current_editor)

    local goto_module = require("goto")
    goto_module.draw(current_editor.goto_state)

    if not welcome.is_showing() then
        local scrollbar = require("scrollbar")
        local content_area = {
            x = 0,
            y = content_start_y,
            w = love.graphics.getWidth(),
            h = love.graphics.getHeight() - content_start_y
        }
        scrollbar.draw(current_editor, current_buffer, content_area)
    end

    local file_dialog = require("file_dialog")
    file_dialog.draw(current_editor)

    local actions_menu = require("actions_menu")
    actions_menu.draw(current_editor.actions_menu)
    
    color_preview.draw(current_editor, current_buffer)
    
    colors.set_color("text_dim")

    if not welcome.is_showing() then
        local debug_text = string.format("Line %d/%d (showing %d-%d)", 
            current_editor.cursor_line, #current_buffer.lines,
            current_editor.viewport.top_line, end_line)
        
        if editor.has_selection(current_editor) then
            debug_text = debug_text .. " [SELECTION]"
        end
        
        if current_editor.search.active then
            debug_text = debug_text .. " [SEARCH]"
        end
        love.graphics.print(debug_text, 10, love.graphics.getHeight() - 20)
    end
end

function love.quit()
    print("Natura Editor closing...")
end