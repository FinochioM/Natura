local love = require("love")

local buffer = {
    lines = {""},
    cursor_line = 1,
    cursor_col = 0,
}

function love.load()
    love.window.setTitle("Natura Editor")
    love.window.setMode(800, 600, {
        resizable = true,
        minwidth = 400,
        minheight = 300
    })
    
    love.keyboard.setKeyRepeat(true)
    print("Natura Editor starting...")
end

function love.textinput(text)
    local line = buffer.lines[buffer.cursor_line]
    local before = string.sub(line, 1, buffer.cursor_col)
    local after = string.sub(line, buffer.cursor_col + 1)
    buffer.lines[buffer.cursor_line] = before .. text .. after
    buffer.cursor_col = buffer.cursor_col + #text
end

function love.keypressed(key)
    if key == "return" then
        local line = buffer.lines[buffer.cursor_line]
        local before = string.sub(line, 1, buffer.cursor_col)
        local after = string.sub(line, buffer.cursor_col + 1)
        
        buffer.lines[buffer.cursor_line] = before
        table.insert(buffer.lines, buffer.cursor_line + 1, after)
        buffer.cursor_line = buffer.cursor_line + 1
        buffer.cursor_col = 0
        
    elseif key == "backspace" then
        if buffer.cursor_col > 0 then
            local line = buffer.lines[buffer.cursor_line]
            local before = string.sub(line, 1, buffer.cursor_col - 1)
            local after = string.sub(line, buffer.cursor_col + 1)
            buffer.lines[buffer.cursor_line] = before .. after
            buffer.cursor_col = buffer.cursor_col - 1
        elseif buffer.cursor_line > 1 then
            local current_line = buffer.lines[buffer.cursor_line]
            local prev_line = buffer.lines[buffer.cursor_line - 1]
            buffer.cursor_col = #prev_line
            buffer.lines[buffer.cursor_line - 1] = prev_line .. current_line
            table.remove(buffer.lines, buffer.cursor_line)
            buffer.cursor_line = buffer.cursor_line - 1
        end
        
    elseif key == "left" then
        if buffer.cursor_col > 0 then
            buffer.cursor_col = buffer.cursor_col - 1
        elseif buffer.cursor_line > 1 then
            buffer.cursor_line = buffer.cursor_line - 1
            buffer.cursor_col = #buffer.lines[buffer.cursor_line]
        end
        
    elseif key == "right" then
        local line = buffer.lines[buffer.cursor_line]
        if buffer.cursor_col < #line then
            buffer.cursor_col = buffer.cursor_col + 1
        elseif buffer.cursor_line < #buffer.lines then
            buffer.cursor_line = buffer.cursor_line + 1
            buffer.cursor_col = 0
        end
        
    elseif key == "up" then
        if buffer.cursor_line > 1 then
            buffer.cursor_line = buffer.cursor_line - 1
            local line = buffer.lines[buffer.cursor_line]
            buffer.cursor_col = math.min(buffer.cursor_col, #line)
        end
        
    elseif key == "down" then
        if buffer.cursor_line < #buffer.lines then
            buffer.cursor_line = buffer.cursor_line + 1
            local line = buffer.lines[buffer.cursor_line]
            buffer.cursor_col = math.min(buffer.cursor_col, #line)
        end
    end
end

function love.update(dt)
    -- Basic update loop
end

function love.draw()
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("Natura Editor", 10, 10)
    
    local font = love.graphics.getFont()
    local line_height = font:getHeight()
    
    love.graphics.setColor(1, 1, 1)
    
    for i, line in ipairs(buffer.lines) do
        local y = 40 + (i - 1) * line_height
        love.graphics.print(line, 10, y)
    end
    
    local cursor_y = 40 + (buffer.cursor_line - 1) * line_height
    local cursor_text = string.sub(buffer.lines[buffer.cursor_line], 1, buffer.cursor_col)
    local cursor_x = 10 + font:getWidth(cursor_text)
    love.graphics.line(cursor_x, cursor_y, cursor_x, cursor_y + line_height)
end

function love.quit()
    print("Natura Editor closing...")
end