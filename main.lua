local love = require("love")

local buffer = {
    content = "",
    cursor_pos = 0
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
    local before = string.sub(buffer.content, 1, buffer.cursor_pos)
    local after = string.sub(buffer.content, buffer.cursor_pos + 1)

    buffer.content = before .. text .. after
    buffer.cursor_pos = buffer.cursor_pos + #text
end

function love.keypressed(key)
    if key == "backspace" then
        if buffer.cursor_pos > 0 then
            local before = string.sub(buffer.content, 1, buffer.cursor_pos - 1)
            local after = string.sub(buffer.content, buffer.cursor_pos + 1)
            buffer.content = before .. after
            buffer.cursor_pos = buffer.cursor_pos - 1
        end
    elseif key == "left" then
        buffer.cursor_pos = math.max(0, buffer.cursor_pos - 1)

    elseif key == "right" then
        buffer.cursor_pos = math.min(#buffer.content, buffer.cursor_pos + 1)
    end
end

function love.update(dt)
    -- Basic update loop
end

function love.draw()
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("Natura Editor", 10, 10)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(buffer.content, 10, 40)
    
    local font = love.graphics.getFont()
    local cursor_text = string.sub(buffer.content, 1, buffer.cursor_pos)
    local cursor_x = 10 + font:getWidth(cursor_text)
    love.graphics.line(cursor_x, 40, cursor_x, 40 + font:getHeight())
end

function love.quit()
    print("Natura Editor closing...")
end