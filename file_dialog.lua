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
    
    if love.system.getOS() == "Windows" and dialog.current_dir == "" then
        dialog.all_files = file_dialog.get_drives()
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
                
                local attr = lfs.attributes(full_path)
                if attr then
                    local item = {name = entry, type = attr.mode}
                    table.insert(dialog.all_files, item)
                end
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
    
    if item.type == "drive" then
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

return file_dialog