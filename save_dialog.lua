local save_dialog = {}

function save_dialog.create()
    return {
        active = false,
        path = "",
        filename = "untitled.txt",
        cursor_pos = 0,
        pending_buffer = nil
    }
end

function save_dialog.open(dialog, buffer)
    dialog.active = true
    dialog.path = love.filesystem.getWorkingDirectory() or ""
    dialog.filename = "untitled.txt"
    dialog.cursor_pos = #dialog.filename
    dialog.pending_buffer = buffer
end

function save_dialog.close(dialog)
    dialog.active = false
    dialog.filename = "untitled.txt"
    dialog.cursor_pos = 0
    dialog.pending_buffer = nil
end

function save_dialog.execute_save(dialog)
    if not dialog.pending_buffer then return end
    
    local full_path = dialog.path .. "/" .. dialog.filename
    dialog.pending_buffer.filepath = full_path
    dialog.pending_buffer.is_new = false
    
    local buffer = require("buffer")
    local success = buffer.save_file(dialog.pending_buffer)
    
    if success then
        save_dialog.close(dialog)
    end
end

function save_dialog.handle_key(dialog, key)
    if key == "escape" then
        save_dialog.close(dialog)
        return true
    elseif key == "return" then
        save_dialog.execute_save(dialog)
        return true
    elseif key == "backspace" and #dialog.filename > 0 then
        dialog.filename = dialog.filename:sub(1, -2)
        dialog.cursor_pos = #dialog.filename
        return true
    end
    return false
end

function save_dialog.handle_text(dialog, text)
    dialog.filename = dialog.filename .. text
    dialog.cursor_pos = #dialog.filename
end

function save_dialog.draw(dialog)
    if not dialog.active then return end
    
    local colors = require("colors")
    local window_width = love.graphics.getWidth()
    local window_height = love.graphics.getHeight()
    
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, window_width, window_height)
    
    local dialog_width = 500
    local dialog_height = 150
    local x = (window_width - dialog_width) / 2
    local y = (window_height - dialog_height) / 2
    
    colors.set_color("background")
    love.graphics.rectangle("fill", x, y, dialog_width, dialog_height)
    
    colors.set_color("text")
    love.graphics.rectangle("line", x, y, dialog_width, dialog_height)
    
    colors.set_color("text")
    love.graphics.print("Save File As:", x + 20, y + 20)
    
    colors.set_color("text_dim")
    love.graphics.print("Filename:", x + 20, y + 60)
    
    local input_x = x + 120
    local input_y = y + 55
    local input_width = dialog_width - 140
    
    colors.set_color("background_dark")
    love.graphics.rectangle("fill", input_x, input_y, input_width, 30)
    
    colors.set_color("text")
    love.graphics.rectangle("line", input_x, input_y, input_width, 30)
    love.graphics.print(dialog.filename, input_x + 5, input_y + 7)
    
    colors.set_color("text_dim")
    love.graphics.print("Press Enter to save, Escape to cancel", x + 20, y + 110)
end

return save_dialog