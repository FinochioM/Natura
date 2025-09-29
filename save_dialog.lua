local save_dialog = {}

function save_dialog.create()
    local lfs = require("lfs")
    
    local dialog = {
        active = false,
        current_dir = "",
        all_files = {},
        files = {},
        selected_index = 1,
        input = "",
        pending_buffer = nil
    }
    
    if love.system.getOS() == "Windows" then
        dialog.current_dir = ""
    else
        dialog.current_dir = lfs.currentdir() or "/"
    end
    
    return dialog
end

function save_dialog.open(dialog, buffer)
    dialog.active = true
    dialog.pending_buffer = buffer
    dialog.input = "untitled.txt"
    save_dialog.scan_directory(dialog)
end

function save_dialog.close(dialog)
    dialog.active = false
    dialog.input = ""
    dialog.pending_buffer = nil
end

function save_dialog.scan_directory(dialog)
    if not lfs then return end
    
    dialog.all_files = {}
    
    if dialog.current_dir == "" then
        if love.system.getOS() == "Windows" then
            for i = string.byte('A'), string.byte('Z') do
                local drive = string.char(i) .. ":"
                if lfs.attributes(drive .. "\\") then
                    table.insert(dialog.all_files, {name = drive, type = "drive"})
                end
            end
        end
    else
        if dialog.current_dir ~= "/" then
            table.insert(dialog.all_files, {name = "..", type = "directory"})
        end
        
        local success = pcall(function()
            for entry in lfs.dir(dialog.current_dir) do
                if entry ~= "." and entry ~= ".." then
                    local full_path = dialog.current_dir .. "/" .. entry
                    if love.system.getOS() == "Windows" then
                        full_path = dialog.current_dir .. "\\" .. entry
                    end
                    
                    local attr = lfs.attributes(full_path)
                    if attr and attr.mode == "directory" then
                        table.insert(dialog.all_files, {name = entry, type = "directory"})
                    end
                end
            end
        end)
        
        if not success then
            table.insert(dialog.all_files, {name = "Cannot read directory", type = "error"})
        end
    end
    
    table.sort(dialog.all_files, function(a, b)
        return a.name < b.name
    end)
    
    save_dialog.filter_files(dialog)
end

function save_dialog.filter_files(dialog)
    dialog.files = {}
    
    if dialog.input == "" then
        for i, file in ipairs(dialog.all_files) do
            dialog.files[i] = file
        end
    else
        local search_lower = dialog.input:lower()
        for _, file in ipairs(dialog.all_files) do
            if file.name:lower():find(search_lower, 1, true) then
                table.insert(dialog.files, file)
            end
        end
    end
    
    if #dialog.files == 0 then
        dialog.selected_index = 0
    else
        dialog.selected_index = math.max(1, math.min(dialog.selected_index, #dialog.files))
    end
end

function save_dialog.go_parent(dialog)
    if not lfs then return end
    
    if love.system.getOS() == "Windows" then
        if dialog.current_dir:match("^%a:$") then
            dialog.current_dir = ""
        elseif dialog.current_dir ~= "" then
            dialog.current_dir = dialog.current_dir:match("(.+)\\") or ""
        end
    else
        if dialog.current_dir ~= "/" then
            dialog.current_dir = dialog.current_dir:match("(.+)/") or "/"
        end
    end
    save_dialog.scan_directory(dialog)
    dialog.selected_index = 1
end

function save_dialog.navigate_to_selected(dialog)
    if dialog.selected_index < 1 or dialog.selected_index > #dialog.files then
        return false
    end
    
    local item = dialog.files[dialog.selected_index]
    
    if item.type == "drive" then
        dialog.current_dir = item.name .. "\\"
        dialog.input = ""
        save_dialog.scan_directory(dialog)
        dialog.selected_index = 1
        return true
    elseif item.type == "directory" then
        if item.name == ".." then
            save_dialog.go_parent(dialog)
        else
            if love.system.getOS() == "Windows" then
                dialog.current_dir = dialog.current_dir .. "\\" .. item.name
            else
                dialog.current_dir = dialog.current_dir .. "/" .. item.name
            end
            dialog.input = ""
            save_dialog.scan_directory(dialog)
            dialog.selected_index = 1
        end
        return true
    end
    return false
end

function save_dialog.execute_save(dialog)
    if not dialog.pending_buffer then return end
    if dialog.input == "" then return end
    
    local full_path
    if love.system.getOS() == "Windows" then
        full_path = dialog.current_dir .. "\\" .. dialog.input
    else
        full_path = dialog.current_dir .. "/" .. dialog.input
    end
    
    dialog.pending_buffer.filepath = full_path
    dialog.pending_buffer.is_new = false
    
    local buffer = require("buffer")
    local ed = _G.current_editor
    local success = buffer.save_file(dialog.pending_buffer, ed)
    
    if success then
        save_dialog.close(dialog)
    end
end

function save_dialog.handle_text(dialog, text)
    dialog.input = dialog.input .. text
    save_dialog.filter_files(dialog)
end

function save_dialog.handle_key(dialog, key)
    if key == "up" and dialog.selected_index > 1 then
        dialog.selected_index = dialog.selected_index - 1
        return true
    elseif key == "down" and dialog.selected_index < #dialog.files then
        dialog.selected_index = dialog.selected_index + 1
        return true
    elseif key == "return" then
        -- If a directory is selected, navigate into it
        if dialog.selected_index > 0 and dialog.selected_index <= #dialog.files then
            local item = dialog.files[dialog.selected_index]
            if item.type == "directory" or item.type == "drive" then
                save_dialog.navigate_to_selected(dialog)
                return true
            end
        end
        -- Otherwise, save with the input as filename
        save_dialog.execute_save(dialog)
        return true
    elseif key == "backspace" then
        if #dialog.input > 0 then
            dialog.input = dialog.input:sub(1, -2)
            save_dialog.filter_files(dialog)
            return true
        else
            save_dialog.go_parent(dialog)
            return true
        end
    end
    return false
end

function save_dialog.draw(dialog)
    if not dialog.active then return end
    
    local colors = require("colors")
    local window_width = love.graphics.getWidth()
    local window_height = love.graphics.getHeight()
    local dialog_width = 500
    local dialog_height = 400
    local dialog_x = (window_width - dialog_width) / 2
    local dialog_y = (window_height - dialog_height) / 2
    
    colors.set_color("background_dark")
    love.graphics.rectangle("fill", dialog_x, dialog_y, dialog_width, dialog_height)
    
    colors.set_color("ui_dim")
    love.graphics.rectangle("line", dialog_x, dialog_y, dialog_width, dialog_height)
    
    colors.set_color("text")
    love.graphics.print("Save File", dialog_x + 10, dialog_y + 10)
    
    colors.set_color("text_dim")
    local current_dir = dialog.current_dir
    if current_dir == "" then
        current_dir = "Drives"
    end
    love.graphics.print("Directory: " .. current_dir, dialog_x + 10, dialog_y + 30)
    
    colors.set_color("text_dim")
    love.graphics.print("Filename: " .. dialog.input, dialog_x + 10, dialog_y + 50)
    
    local font = love.graphics.getFont()
    local line_height = font:getHeight()
    local list_start_y = dialog_y + 70
    local visible_items = math.floor((dialog_height - 100) / line_height)
    
    for i = 1, math.min(#dialog.files, visible_items) do
        local file = dialog.files[i]
        local y = list_start_y + (i - 1) * line_height
        
        if i == dialog.selected_index then
            colors.set_color("selection_active")
            love.graphics.rectangle("fill", dialog_x + 5, y - 2, dialog_width - 10, line_height + 4)
        end
        
        if file.type == "directory" or file.type == "drive" then
            colors.set_color("ui_success")
            love.graphics.print("[" .. file.name .. "]", dialog_x + 10, y)
        elseif file.type == "error" then
            colors.set_color("ui_error")
            love.graphics.print(file.name, dialog_x + 10, y)
        else
            colors.set_color("text")
            love.graphics.print(file.name, dialog_x + 10, y)
        end
    end
    
    if #dialog.files == 0 and dialog.input ~= "" then
        colors.set_color("text_dim")
        love.graphics.print("No folders match", dialog_x + 10, list_start_y)
    end
    
    colors.set_color("text_dim")
    love.graphics.print("Enter: navigate/save | Esc: cancel", dialog_x + 10, dialog_y + dialog_height - 25)
end

return save_dialog