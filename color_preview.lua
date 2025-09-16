local color_preview = {}
local buffer = require("buffer")
local editor = require("editor")
local colors = require("colors")
local syntax = require("syntax")

local preview_active = false
local preview_buffer = nil
local preview_editor = nil
local selected_language = "lua"
local available_languages = {"lua"} -- Can be extended later
local selected_language_index = 1

local preview_window = {
    active = false,
    x = 0,
    y = 0,
    width = 400,
    height = 500,
    resizing = false,
    resize_edge = nil, -- "left", "bottom", "corner"
    offset_from_right = 10, -- Distance from right edge of screen
    offset_from_bottom = 10 -- Distance from bottom edge of screen
}

local live_colors = {}

local sample_code = {
    lua = [[-- Lua Sample Code
local function fibonacci(n)
    if n <= 1 then
        return n
    end
    return fibonacci(n - 1) + fibonacci(n - 2)
end

-- String and numbers
local message = "Hello, World!"
local number = 42
local pi = 3.14159

-- Table operations
local colors = {
    red = "#FF0000",
    green = "#00FF00", 
    blue = "#0000FF"
}

-- Loop and conditional
for i = 1, 10 do
    if i % 2 == 0 then
        print("Even: " .. i)
    else
        print("Odd: " .. i)
    end
end

-- Function with multiple return values
function get_name_age()
    return "Alice", 25
end]]
}

function color_preview.find_colors_section_bounds(buf)
    local colors_start = nil
    local colors_end = nil
    
    for i = 1, #buf.lines do
        local line = buf.lines[i]:gsub("^%s*", ""):gsub("%s*$", "") -- trim whitespace
        
        if line:match("^# Color Theme") then
            colors_start = i
        elseif colors_start and line:match("^# ") and not line:match("^# Color Theme") then
            colors_end = i - 1
            break
        end
    end
    
    if colors_start and not colors_end then
        colors_end = #buf.lines
    end
    
    return colors_start, colors_end
end

function color_preview.is_in_colors_section(buf, cursor_line)
    if not buf.filepath or not buf.filepath:match("%.config$") then
        return false
    end
    
    local colors_start, colors_end = color_preview.find_colors_section_bounds(buf)
    
    if not colors_start then
        return false
    end
    
    if cursor_line >= colors_start and cursor_line <= colors_end then
        return true
    end
    
    return false
end

function color_preview.should_show_preview(ed, buf)
    return color_preview.is_in_colors_section(buf, ed.cursor_line)
end

function color_preview.parse_live_colors(buf)
    live_colors = {}
    
    if not buf.filepath or not buf.filepath:match("%.config$") then
        return
    end
    
    local colors_start, colors_end = color_preview.find_colors_section_bounds(buf)
    if not colors_start then
        return
    end
    
    for i = colors_start, colors_end do
        local line = buf.lines[i]
        local color_name, color_value = line:match("^%s*colors%.([%w_]+):%s*([%x]+)")
        if color_name and color_value then
            if #color_value == 8 then -- RRGGBBAA
                local r = tonumber(color_value:sub(1, 2), 16) / 255
                local g = tonumber(color_value:sub(3, 4), 16) / 255
                local b = tonumber(color_value:sub(5, 6), 16) / 255
                local a = tonumber(color_value:sub(7, 8), 16) / 255
                live_colors[color_name] = {r, g, b, a}
            elseif #color_value == 6 then -- RRGGBB
                local r = tonumber(color_value:sub(1, 2), 16) / 255
                local g = tonumber(color_value:sub(3, 4), 16) / 255
                local b = tonumber(color_value:sub(5, 6), 16) / 255
                live_colors[color_name] = {r, g, b, 1.0}
            end
        end
    end
end

function color_preview.get_live_color(color_name)
    return live_colors[color_name] or colors.get(color_name)
end

function color_preview.update_window_position()
    local window_width = love.graphics.getWidth()
    local window_height = love.graphics.getHeight()
    
    preview_window.x = window_width - preview_window.width - preview_window.offset_from_right
    preview_window.y = window_height - preview_window.height - preview_window.offset_from_bottom
    
    preview_window.x = math.max(10, preview_window.x)
    preview_window.y = math.max(50, preview_window.y)
end

function color_preview.create_preview_buffer()
    if not preview_buffer then
        preview_buffer = buffer.create()
        preview_buffer.language = selected_language
        
        local sample = sample_code[selected_language] or "-- No sample available"
        preview_buffer.lines = buffer.split_lines(sample)
        syntax.tokenize_buffer(preview_buffer)
    end
    
    if not preview_editor then
        preview_editor = editor.create()
    end
    
    return preview_buffer, preview_editor
end

function color_preview.show()
    if preview_active then return end
    
    preview_active = true
    preview_window.active = true
    
    color_preview.create_preview_buffer()
    color_preview.update_window_position()
    print("Color preview activated")
end

function color_preview.hide()
    preview_active = false
    preview_window.active = false
    print("Color preview hidden")
end

function color_preview.toggle()
    if preview_active then
        color_preview.hide()
    else
        color_preview.show()
    end
end

function color_preview.set_language(lang)
    if sample_code[lang] then
        selected_language = lang
        if preview_buffer then
            local sample = sample_code[lang]
            preview_buffer.lines = buffer.split_lines(sample)
            preview_buffer.language = lang
            syntax.tokenize_buffer(preview_buffer)
        end
    end
end

function color_preview.next_language()
    selected_language_index = selected_language_index + 1
    if selected_language_index > #available_languages then
        selected_language_index = 1
    end
    color_preview.set_language(available_languages[selected_language_index])
end

function color_preview.prev_language()
    selected_language_index = selected_language_index - 1
    if selected_language_index < 1 then
        selected_language_index = #available_languages
    end
    color_preview.set_language(available_languages[selected_language_index])
end

function color_preview.update(ed, buf)
    local should_show = color_preview.should_show_preview(ed, buf)
    
    if should_show and not preview_active then
        color_preview.show()
    elseif not should_show and preview_active then
        color_preview.hide()
    end
    
    if preview_active then
        color_preview.update_window_position()
        color_preview.parse_live_colors(buf)
    end
end

function color_preview.get_resize_cursor(mx, my)
    if not preview_window.active then return nil end
    
    local x, y, w, h = preview_window.x, preview_window.y, preview_window.width, preview_window.height
    local edge_size = 10
    
    if mx >= x and mx <= x + edge_size and my >= y and my <= y + edge_size then
        return "corner"
    end
    
    if mx >= x and mx <= x + edge_size and my >= y and my <= y + h then
        return "left"
    end
    
    if mx >= x and mx <= x + w and my >= y and my <= y + edge_size then
        return "top"
    end
    
    return nil
end

function color_preview.start_resize(mx, my)
    local edge = color_preview.get_resize_cursor(mx, my)
    if edge then
        preview_window.resizing = true
        preview_window.resize_edge = edge
        return true
    end
    return false
end

function color_preview.handle_resize(mx, my)
    if not preview_window.resizing then return end
    
    local edge = preview_window.resize_edge
    local window_width = love.graphics.getWidth()
    local window_height = love.graphics.getHeight()
    
    if edge == "left" or edge == "corner" then
        local new_x = math.max(10, mx)
        local new_width = (preview_window.x + preview_window.width) - new_x
        new_width = math.max(200, new_width)
        
        preview_window.x = (preview_window.x + preview_window.width) - new_width
        preview_window.width = new_width
        
        preview_window.offset_from_right = window_width - (preview_window.x + preview_window.width)
    end
    
    if edge == "top" or edge == "corner" then
        local new_y = math.max(50, my)
        local new_height = (preview_window.y + preview_window.height) - new_y
        new_height = math.max(150, new_height)
        
        preview_window.y = (preview_window.y + preview_window.height) - new_height
        preview_window.height = new_height
        
        preview_window.offset_from_bottom = window_height - (preview_window.y + preview_window.height)
    end
end

function color_preview.stop_resize()
    preview_window.resizing = false
    preview_window.resize_edge = nil
end

local function draw_highlighted_line(line, x, y, line_num, language)
    if not language then
        love.graphics.setColor(color_preview.get_live_color("code_default"))
        love.graphics.print(line, x, y)
        return
    end
    
    local tokens = syntax.get_line_tokens(preview_buffer, line_num)
    
    if #tokens == 0 then
        love.graphics.setColor(color_preview.get_live_color("code_default"))
        love.graphics.print(line, x, y)
        return
    end
    
    local current_x = x
    local last_end = 1
    
    for _, token in ipairs(tokens) do
        if token.start > last_end then
            local before_text = line:sub(last_end, token.start - 1)
            love.graphics.setColor(color_preview.get_live_color("code_default"))
            love.graphics.print(before_text, current_x, y)
            current_x = current_x + love.graphics.getFont():getWidth(before_text)
        end
        
        local token_text = line:sub(token.start, token.start + token.length - 1)
        
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
        local color_name = color_map[token.type] or "code_default"
        love.graphics.setColor(color_preview.get_live_color(color_name))
        love.graphics.print(token_text, current_x, y)
        current_x = current_x + love.graphics.getFont():getWidth(token_text)
        
        last_end = token.start + token.length
    end
    
    if last_end <= #line then
        local remaining_text = line:sub(last_end)
        love.graphics.setColor(color_preview.get_live_color("code_default"))
        love.graphics.print(remaining_text, current_x, y)
    end
end

function color_preview.draw()
    if not preview_window.active then return end
    
    love.graphics.setColor(color_preview.get_live_color("background_dark"))
    love.graphics.rectangle("fill", preview_window.x, preview_window.y, preview_window.width, preview_window.height)
    
    love.graphics.setColor(color_preview.get_live_color("ui_dim"))
    love.graphics.rectangle("line", preview_window.x, preview_window.y, preview_window.width, preview_window.height)
    
    love.graphics.setColor(color_preview.get_live_color("text"))
    love.graphics.print("Color Preview", preview_window.x + 10, preview_window.y + 10)
    
    local lang_y = preview_window.y + 30
    love.graphics.setColor(color_preview.get_live_color("text_dim"))
    love.graphics.print("Language:", preview_window.x + 10, lang_y)
    
    local btn_x = preview_window.x + 80
    love.graphics.setColor(color_preview.get_live_color("ui_neutral"))
    love.graphics.rectangle("fill", btn_x - 2, lang_y - 2, 20, 16)
    love.graphics.setColor(color_preview.get_live_color("text"))
    love.graphics.print("<", btn_x, lang_y)
    
    love.graphics.setColor(color_preview.get_live_color("text"))
    love.graphics.print(selected_language, btn_x + 25, lang_y)
    
    local next_btn_x = btn_x + 25 + love.graphics.getFont():getWidth(selected_language) + 5
    love.graphics.setColor(color_preview.get_live_color("ui_neutral"))
    love.graphics.rectangle("fill", next_btn_x - 2, lang_y - 2, 20, 16)
    love.graphics.setColor(color_preview.get_live_color("text"))
    love.graphics.print(">", next_btn_x, lang_y)
    
    if preview_buffer and preview_editor then
        local font = love.graphics.getFont()
        local line_height = font:getHeight()
        local start_y = preview_window.y + 60
        local max_lines = math.floor((preview_window.height - 70) / line_height)
        
        for i = 1, math.min(#preview_buffer.lines, max_lines) do
            local line = preview_buffer.lines[i]
            local y = start_y + (i - 1) * line_height
            
            draw_highlighted_line(line, preview_window.x + 10, y, i, preview_buffer.language)
        end
    end
    
    local edge_size = 10
    local x, y, w, h = preview_window.x, preview_window.y, preview_window.width, preview_window.height

    love.graphics.setColor(color_preview.get_live_color("ui_dim"))
    love.graphics.rectangle("fill", x, y + 20, 2, h - 40)

    love.graphics.rectangle("fill", x + 20, y, w - 40, 2)

    love.graphics.rectangle("fill", x, y, edge_size, edge_size)
end

function color_preview.handle_mouse_pressed(mx, my, button)
    if not preview_window.active then return false end
    
    if button == 1 then -- left click
        if color_preview.start_resize(mx, my) then
            return true
        end
        
        local btn_x = preview_window.x + 80
        local lang_y = preview_window.y + 30
        
        if mx >= btn_x - 2 and mx <= btn_x + 18 and my >= lang_y - 2 and my <= lang_y + 14 then
            color_preview.prev_language()
            return true
        end
        
        local next_btn_x = btn_x + 25 + love.graphics.getFont():getWidth(selected_language) + 5
        if mx >= next_btn_x - 2 and mx <= next_btn_x + 18 and my >= lang_y - 2 and my <= lang_y + 14 then
            color_preview.next_language()
            return true
        end
    end
    
    return false
end

function color_preview.handle_mouse_moved(mx, my)
    if preview_window.resizing then
        color_preview.handle_resize(mx, my)
        return true
    end
    
    local edge = color_preview.get_resize_cursor(mx, my)
    if edge then
        -- love.mouse.setCursor() -- Would need to create resize cursors
        return true
    end
    
    return false
end

function color_preview.handle_mouse_released(mx, my, button)
    if button == 1 and preview_window.resizing then
        color_preview.stop_resize()
        return true
    end
    return false
end

function color_preview.handle_key(key)
    if not preview_active then return false end
    
    if key == "right" then
        color_preview.next_language()
        return true
    elseif key == "left" then
        color_preview.prev_language()
        return true
    end
    
    return false
end

return color_preview