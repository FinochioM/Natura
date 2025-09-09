local love = require("love")
local buffer = require("buffer")
local editor = require("editor")
local keymap = require("keymap")

local current_buffer
local current_editor

function love.load(args)
    love.window.setTitle("Natura Editor")
    love.window.setMode(800, 600, {
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
    current_editor.cursor_col = buffer.insert_text(current_buffer, current_editor.cursor_line, current_editor.cursor_col, text)
    editor.update_viewport(current_editor, current_buffer)
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
    -- Basic update loop
end

function love.draw()
    love.graphics.clear(0.1, 0.1, 0.1)
    
    local title = "Natura Editor"
    if current_buffer.filepath then
        title = title .. " - " .. current_buffer.filepath
        if current_buffer.dirty then
            title = title .. " *"
        end
    end
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print(title, 10, 10)
    
    local font = love.graphics.getFont()
    local line_height = font:getHeight()
    local content_start_y = 40
    
    love.graphics.setColor(1, 1, 1)
    
    local visible_lines = editor.get_visible_line_count()
    local end_line = math.min(#current_buffer.lines, current_editor.viewport.top_line + visible_lines - 1)
    
    for i = current_editor.viewport.top_line, end_line do
        local line = current_buffer.lines[i]
        local y = content_start_y + (i - current_editor.viewport.top_line) * line_height
        love.graphics.print(line, 10, y)
    end
    
    if current_editor.cursor_line >= current_editor.viewport.top_line and 
       current_editor.cursor_line <= current_editor.viewport.top_line + visible_lines - 1 then
        local cursor_y = content_start_y + (current_editor.cursor_line - current_editor.viewport.top_line) * line_height
        local cursor_text = string.sub(current_buffer.lines[current_editor.cursor_line], 1, current_editor.cursor_col)
        local cursor_x = 10 + font:getWidth(cursor_text)
        love.graphics.line(cursor_x, cursor_y, cursor_x, cursor_y + line_height)
    end
    
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.print(string.format("Line %d/%d (showing %d-%d)", 
        current_editor.cursor_line, #current_buffer.lines,
        current_editor.viewport.top_line, end_line), 10, love.graphics.getHeight() - 20)
end

function love.quit()
    print("Natura Editor closing...")
end