local langs = require("langs.init")
local syntax = require("syntax")

local buffer = {}

function buffer.create()
    return {
        lines = {""},
        filepath = nil,
        dirty = false,
        last_modified = 0
    }
end

function buffer.create_new_file(buf)
    buf.lines = {""}
    buf.filepath = nil
    buf.dirty = false
    buf.language = nil
    buf.last_modified = nil
    buf.is_new = true
    
    local syntax = require("syntax")
    syntax.invalidate_buffer(buf)
end

function buffer.get_file_mtime(filepath)
    if not filepath then return 0 end
    
    local lfs = require("lfs")
    local attr = lfs.attributes(filepath)
    return attr and attr.modification or 0
end

local function detect_language(filepath)
    if not filepath then return nil end
    local extension = filepath:match("%.([^./\\]+)$")
    if extension then
        return langs.get_language_from_extension("." .. extension)
    end
    return nil
end

function buffer.load_file(buf, filepath)
    local file = io.open(filepath, "r")
    if not file then 
        print("Error: Cannot open file " .. filepath)
        return false
    end
    
    local content = file:read("*all")
    file:close()
    
    buf.lines = {}
    for line in content:gmatch("([^\r\n]*)\r?\n?") do
        table.insert(buf.lines, line)
    end
    
    if #buf.lines == 0 then
        buf.lines = {""}
    end
    
    buf.filepath = filepath
    buf.dirty = false
    buf.original_timestamp = love.filesystem.getInfo(filepath) and love.filesystem.getInfo(filepath).modtime or 0
    
    local project = require("project")
    local filename = filepath:match("([^\\/]+)$")
    local project_lang = project.get_language_for_file(filename)
    
    if project_lang then
        buf.language = project_lang
    else
        buf.language = detect_language(filepath)
    end
    
    syntax.tokenize_buffer(buf)
    
    return true
end

function buffer.load_file_external(buf, filepath)
    local file = io.open(filepath, "r")
    if not file then
        return false
    end
    
    local content = file:read("*all")
    file:close()
    
    buf.lines = buffer.split_lines(content)
    buf.filepath = filepath
    buf.dirty = false
    buf.last_modified = buffer.get_file_mtime(filepath)
    
    local project = require("project")
    local filename = filepath:match("([^\\/]+)$")
    local project_lang = project.get_language_for_file(filename)
    
    if project_lang then
        buf.language = project_lang
    else
        buf.language = detect_language(filepath)
    end
    
    syntax.tokenize_buffer(buf)
    
    return true
end

function buffer.check_external_modification(buf)
    if not buf.filepath or buf.dirty then
        return false
    end
    
    local current_mtime = buffer.get_file_mtime(buf.filepath)
    return current_mtime > buf.last_modified
end

function buffer.reload_from_disk(buf)
    if not buf.filepath then return false end
    
    local success
    if buf.filepath:find("^[A-Za-z]:\\") or buf.filepath:find("^/") then
        success = buffer.load_file_external(buf, buf.filepath)
    else
        success = buffer.load_file(buf, buf.filepath)
    end
    
    if success and not buf.language then
        buf.language = detect_language(buf.filepath)
    end
    
    return success
end

function buffer.split_lines(content)
    local lines = {}
    
    content = content:gsub("\r\n", "\n"):gsub("\r", "\n")
    
    local start = 1
    while true do
        local pos = content:find("\n", start)
        if not pos then
            local line = content:sub(start)
            table.insert(lines, line)
            break
        else
            local line = content:sub(start, pos - 1)
            table.insert(lines, line)
            start = pos + 1
        end
    end
    
    if #lines == 0 then
        table.insert(lines, "")
    end
    
    return lines
end

function buffer.save_file(buf, ed)
    if not buf.filepath then
        local save_dialog = require("save_dialog")
        save_dialog.open(ed.save_dialog, buf)
        return false
    end
    
    local content = table.concat(buf.lines, "\n")
    
    local file = io.open(buf.filepath, "w")
    if not file then
        return false
    end
    
    file:write(content)
    file:close()
    
    local was_new = buf.is_new
    buf.dirty = false
    buf.is_new = false
    buf.last_modified = buffer.get_file_mtime(buf.filepath)
    
    if was_new then
        local extension = buf.filepath:match("%.([^./\\]+)$")
        if extension then
            buf.language = langs.get_language_from_extension("." .. extension)
            if buf.language then
                syntax.tokenize_buffer(buf)
            end
        end
    end
    
    if buf.filepath:match("natura%.config$") then
        local colors = require("colors")
        colors.reload()
    end
    
    return true
end

function buffer.mark_dirty(buf)
    buf.dirty = true
    local syntax = require("syntax")
    syntax.invalidate_buffer(buf)
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

function buffer.delete_text(buf, line, col, length)
    if line < 1 or line > #buf.lines then return "" end
    
    local line_content = buf.lines[line]
    if col < 0 or col >= #line_content then return "" end
    
    local end_col = math.min(col + length, #line_content)
    local deleted_text = string.sub(line_content, col + 1, end_col)
    
    buf.lines[line] = string.sub(line_content, 1, col) .. string.sub(line_content, end_col + 1)
    buffer.mark_dirty(buf)
    
    return deleted_text
end

return buffer