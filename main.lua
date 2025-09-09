local love = require("love")
local buffer = require("buffer")
local editor = require("editor")

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
end

function love.keypressed(key)
    if (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) then
        if key == "s" then
            buffer.save_file(current_buffer)
            return
        end
    end
    
    if key == "return" then
        buffer.split_line(current_buffer, current_editor.cursor_line, current_editor.cursor_col)
        current_editor.cursor_line = current_editor.cursor_line + 1
        current_editor.cursor_col = 0
        
    elseif key == "backspace" then
        if current_editor.cursor_col > 0 then
            buffer.delete_char(current_buffer, current_editor.cursor_line, current_editor.cursor_col)
            current_editor.cursor_col = current_editor.cursor_col - 1
        elseif current_editor.cursor_line > 1 then
            current_editor.cursor_col = buffer.join_lines(current_buffer, current_editor.cursor_line)
            current_editor.cursor_line = current_editor.cursor_line - 1
        end
        
    elseif key == "left" then
        editor.move_cursor_left(current_editor, current_buffer)
    elseif key == "right" then
        editor.move_cursor_right(current_editor, current_buffer)
    elseif key == "up" then
        editor.move_cursor_up(current_editor, current_buffer)
    elseif key == "down" then
        editor.move_cursor_down(current_editor, current_buffer)
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
    
    love.graphics.setColor(1, 1, 1)
    
    for i, line in ipairs(current_buffer.lines) do
        local y = 40 + (i - 1) * line_height
        love.graphics.print(line, 10, y)
    end
    
    local cursor_y = 40 + (current_editor.cursor_line - 1) * line_height
    local cursor_text = string.sub(current_buffer.lines[current_editor.cursor_line], 1, current_editor.cursor_col)
    local cursor_x = 10 + font:getWidth(cursor_text)
    love.graphics.line(cursor_x, cursor_y, cursor_x, cursor_y + line_height)
end

function love.quit()
    print("Natura Editor closing...")
end