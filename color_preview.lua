local color_preview = {}
local buffer = require("buffer")
local editor = require("editor")
local colors = require("colors")
local syntax = require("syntax")

local preview_active = false
local preview_buffer = nil
local preview_editor = nil
local selected_language = "lua"
local preview_window = {
    active = false,
    x = 0,
    y = 0,
    width = 400,
    height = 500
}

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

function color_preview.is_in_colors_section(buf, cursor_line)
    if not buf.filepath or not buf.filepath:match("%.config$") then
        return false
    end
    
    for i = math.max(1, cursor_line - 10), math.min(#buf.lines, cursor_line + 5) do
        local line = buf.lines[i]:lower():gsub("%s+", "")
        if line:match("^colors%.") or line == "[colors]" then
            return true
        end
    end
    
    return false
end

function color_preview.should_show_preview(ed, buf)
    return color_preview.is_in_colors_section(buf, ed.cursor_line)
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

function color_preview.update(ed, buf)
    local should_show = color_preview.should_show_preview(ed, buf)
    
    if should_show and not preview_active then
        color_preview.show()
    elseif not should_show and preview_active then
        color_preview.hide()
    end
    
    if preview_active then
        -- TODO: Parse current config and apply colors to preview
    end
end

function color_preview.draw()
    if not preview_window.active then return end
    
    local window_width = love.graphics.getWidth()
    local window_height = love.graphics.getHeight()
    
    preview_window.x = window_width - preview_window.width - 10
    preview_window.y = 50
    preview_window.height = window_height - 100
    
    love.graphics.setColor(0.15, 0.15, 0.15, 0.95)
    love.graphics.rectangle("fill", preview_window.x, preview_window.y, preview_window.width, preview_window.height)
    
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.rectangle("line", preview_window.x, preview_window.y, preview_window.width, preview_window.height)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Color Preview", preview_window.x + 10, preview_window.y + 10)
    
    love.graphics.print("Language: " .. selected_language, preview_window.x + 10, preview_window.y + 30)
    
    if preview_buffer and preview_editor then
        local font = love.graphics.getFont()
        local line_height = font:getHeight()
        local start_y = preview_window.y + 60
        
        for i = 1, math.min(#preview_buffer.lines, 20) do
            local line = preview_buffer.lines[i]
            local y = start_y + (i - 1) * line_height

            love.graphics.setColor(0.9, 0.9, 0.9)
            love.graphics.print(line, preview_window.x + 10, y)
        end
    end
end

function color_preview.handle_key(key)
    if not preview_active then return false end
    
    if key == "1" then
        color_preview.set_language("lua")
        return true
    end
    
    return false
end

return color_preview