local lines = {""}
local cursor_line = 1
local cursor_col = 0
local filename = "untitled.txt"
local save_message = ""
local save_timer = 0
local spotlight_active = false
local spotlight_text = ""


function love.textinput(t)
    if spotlight_active then
        spotlight_text = spotlight_text .. t
        return
    end
    
    local line = lines[cursor_line]
    lines[cursor_line] = line:sub(1, cursor_col) .. t .. line:sub(cursor_col + 1)
    cursor_col = cursor_col + 1
end

function love.keypressed(key)
    if love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl") then
        if key == "s" then
            local content = table.concat(lines, "\n")
            love.filesystem.write(filename, content)
            save_message = "Saved to: " .. love.filesystem.getSaveDirectory() .. "/" .. filename
            save_timer = 3
            return
        elseif key == "p" then
            spotlight_active = not spotlight_active
            spotlight_text = ""
            return
        end
    end
    
    if spotlight_active then
        if key == "escape" then
            spotlight_active = false
            spotlight_text = ""
        end
        return
    end
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

function love.update(dt)
    if save_timer > 0 then
        save_timer = save_timer - dt
        if save_timer <= 0 then
            save_message = ""
        end
    end
end

function love.draw()    
    if save_message ~= "" then
        love.graphics.print(save_message, 10, 550)
    end
    
    for i, line in ipairs(lines) do
        love.graphics.print(line, 10, 30 + i * 20)
    end

    if spotlight_active then
        love.graphics.setColor(0.2, 0.2, 0.2, 0.9)
        love.graphics.rectangle("fill", 200, 250, 400, 30)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", 200, 250, 400, 30)
        love.graphics.print("Search: " .. spotlight_text, 210, 255)
    end
    
    local font = love.graphics.getFont()
    local text_before_cursor = lines[cursor_line]:sub(1, cursor_col)
    local cursor_x = 10 + font:getWidth(text_before_cursor)
    local cursor_y = 30 + cursor_line * 20
    love.graphics.line(cursor_x, cursor_y, cursor_x, cursor_y + font:getHeight())
end