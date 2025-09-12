local love = require("love")
local buffer = require("buffer")
local editor = require("editor")
local keymap = require("keymap")
local search = require("search")
local langs = require("langs.init")
local colors = require("colors") 
local syntax = require("syntax")

local current_buffer
local current_editor

local file_check_timer = 0
local file_check_interval = 1.0

function love.load(args)
    local config = require("config")
    config.load()

    local colors = require("colors")
    colors.load()

    local keymap = require("keymap")
    keymap.load_keybinds()

    love.window.setTitle("Natura Editor")
    local window_width = config.get("window_width")
    local window_height = config.get("window_height")
    
    love.window.setMode(window_width, window_height, {
        resizable = true,
        minwidth = 400,
        minheight = 300
    })
    
    love.keyboard.setKeyRepeat(true)
    
    current_buffer = buffer.create()
    current_editor = editor.create()
    
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

function love.textinput(text)
    if current_editor.file_dialog.active then
        local file_dialog = require("file_dialog")
        file_dialog.handle_text(current_editor.file_dialog, text)
    elseif current_editor.goto_state.active then
        local goto_module = require("goto")
        goto_module.handle_input(current_editor.goto_state, text)
    elseif current_editor.search.active then
        current_editor.search.query = current_editor.search.query .. text
        search.set_query(current_editor.search, current_editor.search.query, current_buffer)
    else
        if editor.has_selection(current_editor) then
            local actions = require("actions")
            actions.delete_selection(current_editor, current_buffer)
        end
        
        local undo = require("undo")
        undo.record_insertion(current_editor.undo_state, current_editor.cursor_line, current_editor.cursor_col, text, current_editor)
        
        current_editor.cursor_col = buffer.insert_text(current_buffer, current_editor.cursor_line, current_editor.cursor_col, text)
        editor.update_viewport(current_editor, current_buffer)
    end
end

function love.keypressed(key)
    if not keymap.handle_key(key, current_editor, current_buffer) then
        print("Unhandled key: " .. key)
    end
end

function love.wheelmoved(x, y)
    if y > 0 then
        editor.scroll_up(current_editor, current_buffer, 3)
    elseif y < 0 then
        editor.scroll_down(current_editor, current_buffer, 3)
    end
end

function love.update(dt)
    file_check_timer = file_check_timer + dt
    
    if file_check_timer >= file_check_interval then
        file_check_timer = 0
        
        if buffer.check_external_modification(current_buffer) then
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
end

local function draw_search_highlights(ed, font, line_height, content_start_y)
    if not ed.search.active or #ed.search.results == 0 then
        return
    end
    
    local visible_lines = editor.get_visible_line_count()
    local viewport_start = ed.viewport.top_line
    local viewport_end = viewport_start + visible_lines - 1
    
    for i, result in ipairs(ed.search.results) do
        if result.line >= viewport_start and result.line <= viewport_end then
            local y = content_start_y + (result.line - viewport_start) * line_height
            local line = current_buffer.lines[result.line]
            local before_text = string.sub(line, 1, result.start_col)
            local match_text = string.sub(line, result.start_col + 1, result.end_col)
            
            local start_x = 10 + font:getWidth(before_text)
            local width = font:getWidth(match_text)
            
            if i == ed.search.current_result then
                love.graphics.setColor(1, 0.7, 0, 0.6)  -- Orange for current result
            else
                love.graphics.setColor(1, 1, 0, 0.3)    -- Yellow for other results
            end
            
            love.graphics.rectangle("fill", start_x, y, width, line_height)
        end
    end
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

local function draw_goto_bar(ed)
    if not ed.goto_state.active then return end
    
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
    local text = "Go to line: " .. ed.goto_state.input
    love.graphics.print(text, bar_x + 5, bar_y + 5)
end

local function draw_file_dialog(ed)
    if not ed.file_dialog.active then return end
    
    local window_width = love.graphics.getWidth()
    local window_height = love.graphics.getHeight()
    local dialog_width = 500
    local dialog_height = 400
    local dialog_x = (window_width - dialog_width) / 2
    local dialog_y = (window_height - dialog_height) / 2
    
    love.graphics.setColor(0.2, 0.2, 0.2, 0.95)
    love.graphics.rectangle("fill", dialog_x, dialog_y, dialog_width, dialog_height)
    
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.rectangle("line", dialog_x, dialog_y, dialog_width, dialog_height)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Open File", dialog_x + 10, dialog_y + 10)
    
    love.graphics.setColor(0.8, 0.8, 0.8)
    local current_dir = ed.file_dialog.current_dir
    if current_dir == "" then
        current_dir = "Drives"
    end
    love.graphics.print("Directory: " .. current_dir, dialog_x + 10, dialog_y + 30)

    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.print("Filter: " .. ed.file_dialog.input, dialog_x + 10, dialog_y + 50)
    
    local font = love.graphics.getFont()
    local line_height = font:getHeight()
    local list_start_y = dialog_y + 70
    local visible_items = math.floor((dialog_height - 100) / line_height)
    
    for i = 1, math.min(#ed.file_dialog.files, visible_items) do
        local file = ed.file_dialog.files[i]
        local y = list_start_y + (i - 1) * line_height
        
        if i == ed.file_dialog.selected_index then
            love.graphics.setColor(0.3, 0.3, 0.6, 0.8)
            love.graphics.rectangle("fill", dialog_x + 5, y - 2, dialog_width - 10, line_height + 5)
        end
        
        if file.type == "directory" or file.type == "drive" then
            love.graphics.setColor(0.6, 0.8, 1)
            love.graphics.print("[" .. file.name .. "]", dialog_x + 10, y)
        elseif file.type == "error" then
            love.graphics.setColor(1, 0.5, 0.5)
            love.graphics.print(file.name, dialog_x + 10, y)
        else
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(file.name, dialog_x + 10, y)
        end
    end

    if #ed.file_dialog.files == 0 and ed.file_dialog.input ~= "" then
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.print("No matches found", dialog_x + 10, list_start_y)
    end
end

function draw_search_highlights(ed, font, line_height, content_start_y)
    local colors = require("colors")
    
    if not ed.search.active or #ed.search.results == 0 then
        return
    end
    
    for i, result in ipairs(ed.search.results) do
        if result.line >= ed.viewport.top_line and result.line <= ed.viewport.top_line + editor.get_visible_line_count() - 1 then
            local y = content_start_y + (result.line - ed.viewport.top_line) * line_height
            local line = current_buffer.lines[result.line]
            local before_match = line:sub(1, result.col - 1)
            local match_text = line:sub(result.col, result.col + result.length - 1)
            
            local x = 10 + font:getWidth(before_match)
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

function draw_selection_highlight(ed, font, line_height, content_start_y)
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
            
            local x = 10 + font:getWidth(before_selection)
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
        ["default"] = "code_default"
    }
    return color_map[token_type] or "code_default"
end

function love.draw()    
    local bg_color = colors.get("background")
    love.graphics.clear(bg_color[1], bg_color[2], bg_color[3], bg_color[4])
    
    colors.set_color("text")
    local title = "Natura Editor"
    if current_buffer.filepath then
        title = title .. " - " .. current_buffer.filepath
        if current_buffer.dirty then
            title = title .. " *"
        end
    end
    love.graphics.print(title, 10, 10)
    
    local font = love.graphics.getFont()
    local line_height = font:getHeight()
    local content_start_y = 40
    
    draw_search_highlights(current_editor, font, line_height, content_start_y)
    draw_selection_highlight(current_editor, font, line_height, content_start_y)
    
    colors.set_color("code_default")
    
    local visible_lines = editor.get_visible_line_count()
    local end_line = math.min(#current_buffer.lines, current_editor.viewport.top_line + visible_lines - 1)

    for i = current_editor.viewport.top_line, end_line do
        local line = current_buffer.lines[i]
        local y = content_start_y + (i - current_editor.viewport.top_line) * line_height
        
        draw_line_with_syntax_highlighting(line, 10, y, i, current_buffer.language) -- Pass line number
    end
        
    if current_editor.cursor_line >= current_editor.viewport.top_line and 
       current_editor.cursor_line <= current_editor.viewport.top_line + visible_lines - 1 then
        local cursor_y = content_start_y + (current_editor.cursor_line - current_editor.viewport.top_line) * line_height
        local cursor_text = string.sub(current_buffer.lines[current_editor.cursor_line], 1, current_editor.cursor_col)
        local cursor_x = 10 + font:getWidth(cursor_text)
        
        colors.set_color("cursor")
        love.graphics.line(cursor_x, cursor_y, cursor_x, cursor_y + line_height)
    end
    
    draw_search_bar(current_editor)
    draw_goto_bar(current_editor)
    draw_file_dialog(current_editor)
    
    colors.set_color("text_dim")
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

function love.quit()
    print("Natura Editor closing...")
end