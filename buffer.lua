local buffer = {}

function buffer.create()
    return {
        lines = {""},
        filepath = nil,
        dirty = false
    }
end

function buffer.load_file(buf, filepath)
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
    
    buf.lines = {}
    for line in content:gmatch("([^\n]*)\n?") do
        if line ~= "" or #buf.lines == 0 then
            table.insert(buf.lines, line)
        end
    end
    
    if #buf.lines == 0 then
        buf.lines = {""}
    end
    
    buf.filepath = filepath
    buf.dirty = false
    
    print("Successfully loaded: " .. filepath)
    return true
end

function buffer.save_file(buf)
    if not buf.filepath then
        print("No filepath set")
        return false
    end
    
    local content = ""
    for i, line in ipairs(buf.lines) do
        content = content .. line
        if i < #buf.lines then
            content = content .. "\n"
        end
    end
    
    local success, error = love.filesystem.write(buf.filepath, content)
    if not success then
        print("Error saving file: " .. (error or "unknown error"))
        return false
    end
    
    buf.dirty = false
    print("Saved: " .. buf.filepath)
    return true
end

function buffer.mark_dirty(buf)
    buf.dirty = true
end

function buffer.insert_text(buf, cursor_line, cursor_col, text)
    local line = buf.lines[cursor_line]
    local before = string.sub(line, 1, cursor_col)
    local after = string.sub(line, cursor_col + 1)
    buf.lines[cursor_line] = before .. text .. after
    buffer.mark_dirty(buf)
    return cursor_col + #text
end

function buffer.split_line(buf, cursor_line, cursor_col)
    local line = buf.lines[cursor_line]
    local before = string.sub(line, 1, cursor_col)
    local after = string.sub(line, cursor_col + 1)
    
    buf.lines[cursor_line] = before
    table.insert(buf.lines, cursor_line + 1, after)
    buffer.mark_dirty(buf)
end

function buffer.delete_char(buf, cursor_line, cursor_col)
    local line = buf.lines[cursor_line]
    local before = string.sub(line, 1, cursor_col - 1)
    local after = string.sub(line, cursor_col + 1)
    buf.lines[cursor_line] = before .. after
    buffer.mark_dirty(buf)
end

function buffer.join_lines(buf, cursor_line)
    local current_line = buf.lines[cursor_line]
    local prev_line = buf.lines[cursor_line - 1]
    local new_cursor_col = #prev_line
    buf.lines[cursor_line - 1] = prev_line .. current_line
    table.remove(buf.lines, cursor_line)
    buffer.mark_dirty(buf)
    return new_cursor_col
end

return buffer