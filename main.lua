local love = require("love")

local buffer = {
    lines = {""},
    cursor_line = 1,
    cursor_col = 0,
    filepath = nil,
    dirty = false
}

local function load_file(filepath)
    print("Attempting to load: " .. filepath)
    
    local info = love.filesystem.getInfo(filepath)
    if not info then
        print("Error: File does not exist: " .. filepath)
        return false
    end
    
    local content, error = love.filesystem.read(filepath)
    if not content then
        print("Error reading file: " .. (error or "unknown error"))
        return false
    end
    
    buffer.lines = {}
    for line in content:gmatch("([^\n]*)\n?") do
        if line ~= "" or #buffer.lines == 0 then
            table.insert(buffer.lines, line)
        end
    end
    
    if #buffer.lines == 0 then
        buffer.lines = {""}
    end
    
    buffer.filepath = filepath
    buffer.dirty = false
    buffer.cursor_line = 1
    buffer.cursor_col = 0
    
    print("Successfully loaded: " .. filepath)
    return true
end

local function save_file()
    if not buffer.filepath then
        print("No filepath set")
        return false
    end
    
    local content = ""
    for i, line in ipairs(buffer.lines) do
        content = content .. line
        if i < #buffer.lines then
            content = content .. "\n"
        end
    end
    
    local success, error = love.filesystem.write(buffer.filepath, content)
    if not success then
        print("Error saving file: " .. (error or "unknown error"))
        return false
    end
    
    buffer.dirty = false
    print("Saved: " .. buffer.filepath)
    return true
end

local function mark_dirty()
    buffer.dirty = true
end

function love.load(args)
    love.window.setTitle("Natura Editor")
    love.window.setMode(800, 600, {
        resizable = true,
        minwidth = 400,
        minheight = 300
    })
    
    love.keyboard.setKeyRepeat(true)
    
    if args and args[1] then
        local filepath = args[1]
        if love.filesystem.getInfo(filepath) then
            load_file(filepath)
        else
            local filename = filepath:match("([^/\\]+)$") or filepath
            if love.filesystem.getInfo(filename) then
                load_file(filename)
            else
                print("Could not find file: " .. filepath)
            end
        end
    end
    
    print("Natura Editor starting...")
end

function love.textinput(text)
    local line = buffer.lines[buffer.cursor_line]
    local before = string.sub(line, 1, buffer.cursor_col)
    local after = string.sub(line, buffer.cursor_col + 1)
    buffer.lines[buffer.cursor_line] = before .. text .. after
    buffer.cursor_col = buffer.cursor_col + #text
    mark_dirty()
end

function love.keypressed(key)
    if (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) then
        if key == "s" then
            save_file()
            return
        end
    end
    
    if key == "return" then
        local line = buffer.lines[buffer.cursor_line]
        local before = string.sub(line, 1, buffer.cursor_col)
        local after = string.sub(line, buffer.cursor_col + 1)
        
        buffer.lines[buffer.cursor_line] = before
        table.insert(buffer.lines, buffer.cursor_line + 1, after)
        buffer.cursor_line = buffer.cursor_line + 1
        buffer.cursor_col = 0
        mark_dirty()
        
    elseif key == "backspace" then
        if buffer.cursor_col > 0 then
            local line = buffer.lines[buffer.cursor_line]
            local before = string.sub(line, 1, buffer.cursor_col - 1)
            local after = string.sub(line, buffer.cursor_col + 1)
            buffer.lines[buffer.cursor_line] = before .. after
            buffer.cursor_col = buffer.cursor_col - 1
            mark_dirty()
        elseif buffer.cursor_line > 1 then
            local current_line = buffer.lines[buffer.cursor_line]
            local prev_line = buffer.lines[buffer.cursor_line - 1]
            buffer.cursor_col = #prev_line
            buffer.lines[buffer.cursor_line - 1] = prev_line .. current_line
            table.remove(buffer.lines, buffer.cursor_line)
            buffer.cursor_line = buffer.cursor_line - 1
            mark_dirty()
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
    love.graphics.clear(0.1, 0.1, 0.1)
    
    local title = "Natura Editor"
    if buffer.filepath then
        title = title .. " - " .. buffer.filepath
        if buffer.dirty then
            title = title .. " *"
        end
    end
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print(title, 10, 10)
    
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