local lines = {""}
local cursor_line = 1
local cursor_col = 0

function love.textinput(t)
    local line = lines[cursor_line]
    lines[cursor_line] = line:sub(1, cursor_col) .. t .. line:sub(cursor_col + 1)
    cursor_col = cursor_col + 1
end

function love.keypressed(key)
    if key == "backspace" then
        if cursor_col > 0 then
            local line = lines[cursor_line]
            lines[cursor_line] = line:sub(1, cursor_col - 1) .. line:sub(cursor_col + 1)
            cursor_col = cursor_col - 1
        elseif cursor_line > 1 then
            local current_line = lines[cursor_line]
            cursor_col = #lines[cursor_line - 1]
            lines[cursor_line - 1] = lines[cursor_line - 1] .. current_line
            table.remove(lines, cursor_line)
            cursor_line = cursor_line - 1
        end
    elseif key == "return" then
        local line = lines[cursor_line]
        local new_line = line:sub(cursor_col + 1)
        lines[cursor_line] = line:sub(1, cursor_col)
        table.insert(lines, cursor_line + 1, new_line)
        cursor_line = cursor_line + 1
        cursor_col = 0
    elseif key == "up" and cursor_line > 1 then
        cursor_line = cursor_line - 1
        cursor_col = math.min(cursor_col, #lines[cursor_line])
    elseif key == "down" and cursor_line < #lines then
        cursor_line = cursor_line + 1
        cursor_col = math.min(cursor_col, #lines[cursor_line])
    elseif key == "left" and cursor_col > 0 then
        cursor_col = cursor_col - 1
    elseif key == "right" and cursor_col < #lines[cursor_line] then
        cursor_col = cursor_col + 1
    end
end

function love.load()
    love.window.setTitle("Natura Editor")
    love.window.setMode(800, 600)
end

function love.draw()    
    for i, line in ipairs(lines) do
        love.graphics.print(line, 10, 30 + i * 20)
    end
    local font = love.graphics.getFont()
    local text_before_cursor = lines[cursor_line]:sub(1, cursor_col)
    local cursor_x = 10 + font:getWidth(text_before_cursor)
    local cursor_y = 30 + cursor_line * 20
    love.graphics.line(cursor_x, cursor_y, cursor_x, cursor_y + font:getHeight())
end