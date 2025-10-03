local file_dialog = {}

package.cpath = package.cpath .. ";a:/Desarrollos/Natura/libs/?.dll"

local lfs_available, lfs_or_error = pcall(require, "lfs")
if not lfs_available then
    print("LuaFileSystem error: " .. tostring(lfs_or_error))
    lfs = nil
else
    lfs = lfs_or_error
    print("LuaFileSystem loaded successfully")
end

function file_dialog.create()
    return {
        active = false,
        current_dir = file_dialog.get_initial_dir(),
        files = {},
        all_files = {},
        selected_index = 1,
        input = ""
    }
end

function file_dialog.get_initial_dir()
    if not lfs then
        return "."
    end
    
    if love.system.getOS() == "Windows" then
        return ""
    else
        return lfs.currentdir() or "/"
    end
end

function file_dialog.toggle(dialog)
    dialog.active = not dialog.active
    if dialog.active then
        dialog.input = ""
        dialog.selected_index = 1
        file_dialog.scan_directory(dialog)
    end
end

function file_dialog.get_drives()
    local drives = {}
    if lfs and love.system.getOS() == "Windows" then
        for i = 65, 90 do
            local drive = string.char(i) .. ":\\"
            local success, attr = pcall(lfs.attributes, drive)
            if success and attr then
                table.insert(drives, {name = string.char(i) .. ":", type = "drive"})
            end
        end
    end
    return drives
end

function file_dialog.scan_directory(dialog)
    dialog.all_files = {}

    local project = require("project")
    
    if project.is_loaded() and dialog.current_dir == file_dialog.get_initial_dir() then
        local proj = project.get_current()
        for _, workspace_dir in ipairs(proj.workspace_dirs) do
            if lfs.attributes(workspace_dir) then
                local dir_name = workspace_dir:match("([^\\/]+)$") or workspace_dir
                table.insert(dialog.all_files, {
                    name = dir_name,
                    full_path = workspace_dir,
                    type = "workspace_dir"
                })
            end
        end
        
        if #proj.workspace_dirs > 0 then
            table.insert(dialog.all_files, {name = "--- Drives ---", type = "separator"})
        end
    end
    
    if love.system.getOS() == "Windows" and dialog.current_dir == "" then
        local drives = file_dialog.get_drives()
        for _, drive in ipairs(drives) do
            table.insert(dialog.all_files, drive)
        end
        dialog.input = ""
        file_dialog.filter_files(dialog)
        return
    end
    
    if dialog.current_dir ~= "/" and dialog.current_dir ~= "" then
        table.insert(dialog.all_files, {name = "..", type = "directory"})
    end
    
    local success, err = pcall(function()
        for entry in lfs.dir(dialog.current_dir) do
            if entry ~= "." and entry ~= ".." then
                local full_path = dialog.current_dir .. "/" .. entry
                if love.system.getOS() == "Windows" then
                    full_path = dialog.current_dir .. "\\" .. entry
                end
                
                if project.should_ignore(full_path, entry) then
                    goto continue
                end
                
                local attr = lfs.attributes(full_path)
                if attr then
                    local item = {name = entry, type = attr.mode}
                    table.insert(dialog.all_files, item)
                end
                
                ::continue::
            end
        end
    end)
    
    if not success then
        table.insert(dialog.all_files, {name = "Cannot read directory", type = "error"})
    end
    
    table.sort(dialog.all_files, function(a, b)
        if a.type == "directory" and b.type ~= "directory" then return true end
        if a.type ~= "directory" and b.type == "directory" then return false end
        return a.name < b.name
    end)
    
    dialog.input = ""
    file_dialog.filter_files(dialog)
end

function file_dialog.handle_text(dialog, text)
    dialog.input = dialog.input .. text
    file_dialog.filter_files(dialog)
end

function file_dialog.handle_key(dialog, key, editor, buffer)
    if key == "up" and dialog.selected_index > 1 then
        dialog.selected_index = dialog.selected_index - 1
        return true
    elseif key == "down" and dialog.selected_index < #dialog.files then
        dialog.selected_index = dialog.selected_index + 1
        return true
    elseif key == "return" then
        return file_dialog.select_item(dialog, editor, buffer)
    elseif key == "backspace" then
        if #dialog.input > 0 then
            dialog.input = dialog.input:sub(1, -2)
            file_dialog.filter_files(dialog)
            return true
        else
            file_dialog.go_parent(dialog)
            return true
        end
    end
    return false
end

function file_dialog.go_parent(dialog)
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
    file_dialog.scan_directory(dialog)
    dialog.selected_index = 1
end

function file_dialog.select_item(dialog, editor, buffer)
    if #dialog.files == 0 or dialog.selected_index < 1 or dialog.selected_index > #dialog.files then
        return false
    end
    
    local item = dialog.files[dialog.selected_index]

    if item.type == "separator" then
        return true
    elseif item.type == "workspace_dir" then
        dialog.current_dir = item.full_path
        file_dialog.scan_directory(dialog)
        dialog.selected_index = 1
        return true
    elseif item.type == "drive" then
        dialog.current_dir = item.name .. "\\"
        file_dialog.scan_directory(dialog)
        dialog.selected_index = 1
        return true
    elseif item.type == "directory" then
        if item.name == ".." then
            file_dialog.go_parent(dialog)
        else
            if love.system.getOS() == "Windows" then
                dialog.current_dir = dialog.current_dir .. "\\" .. item.name
            else
                dialog.current_dir = dialog.current_dir .. "/" .. item.name
            end
            file_dialog.scan_directory(dialog)
            dialog.selected_index = 1
        end
        return true
    elseif item.type == "file" then
        local full_path = dialog.current_dir .. "/" .. item.name
        if love.system.getOS() == "Windows" then
            full_path = dialog.current_dir .. "\\" .. item.name
        end
        
        local file = io.open(full_path, "r")
        if file then
            local content = file:read("*all")
            file:close()
            
            local buffer_module = require("buffer")
            buffer_module.load_file_external(buffer, full_path)
        end
        
        dialog.active = false
        return true
    end
    return false
end

function file_dialog.filter_files(dialog)
    if dialog.input == "" then
        dialog.files = {}
        for i, file in ipairs(dialog.all_files) do
            dialog.files[i] = file
        end
    else
        dialog.files = {}
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

function file_dialog.draw(ed)
    if not ed.file_dialog.active then return end
    
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
    love.graphics.print("Open File", dialog_x + 10, dialog_y + 10)
    
    colors.set_color("text_dim")
    local current_dir = ed.file_dialog.current_dir
    if current_dir == "" then
        current_dir = "Drives"
    end
    love.graphics.print("Directory: " .. current_dir, dialog_x + 10, dialog_y + 30)

    colors.set_color("text_dim")
    love.graphics.print("Filter: " .. ed.file_dialog.input, dialog_x + 10, dialog_y + 50)
    
    local font = love.graphics.getFont()
    local line_height = font:getHeight()
    local list_start_y = dialog_y + 70
    local visible_items = math.floor((dialog_height - 100) / line_height)
    
    for i = 1, math.min(#ed.file_dialog.files, visible_items) do
        local file = ed.file_dialog.files[i]
        local y = list_start_y + (i - 1) * line_height
        
        if i == ed.file_dialog.selected_index then
            colors.set_color("selection_active")
            love.graphics.rectangle("fill", dialog_x + 5, y - 2, dialog_width - 10, line_height + 4)
        end
        
        if file.type == "directory" or file.type == "drive" then
            colors.set_color("ui_success")
            love.graphics.print("[" .. file.name .. "]", dialog_x + 10, y)
        elseif file.type == "separator" then
            colors.set_color("ui_dim")
            love.graphics.print(file.name, dialog_x + 10, y)
        elseif file.type == "error" then
            colors.set_color("ui_error")
            love.graphics.print(file.name, dialog_x + 10, y)
        else
            colors.set_color("text")
            love.graphics.print(file.name, dialog_x + 10, y)
        end
    end

    if #ed.file_dialog.files == 0 and ed.file_dialog.input ~= "" then
        colors.set_color("text_dim")
        love.graphics.print("No matches found", dialog_x + 10, list_start_y)
    end
    
    colors.set_color("text_dim")
    local status_text = string.format("%d files", #ed.file_dialog.files)
    love.graphics.print(status_text, dialog_x + 10, dialog_y + dialog_height - 25)
end

return file_dialog