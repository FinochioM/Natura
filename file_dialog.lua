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
        file_dialog.scan_directory(dialog)
        dialog.input = ""
        dialog.selected_index = 1
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
    dialog.files = {}
  
    if not lfs then
        file_dialog.scan_directory_love(dialog)
        return
    end
    
    if love.system.getOS() == "Windows" and dialog.current_dir == "" then
        dialog.files = file_dialog.get_drives()
        return
    end
    
    if dialog.current_dir ~= "/" and dialog.current_dir ~= "" then
        table.insert(dialog.files, {name = "..", type = "directory"})
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
                    table.insert(dialog.files, item)
                end
            end
        end
    end)
    
    if not success then
        table.insert(dialog.files, {name = "Cannot read directory: " .. (err or "unknown error"), type = "error"})
    end
    
    table.sort(dialog.files, function(a, b)
        if a.type == "directory" and b.type ~= "directory" then return true end
        if a.type ~= "directory" and b.type == "directory" then return false end
        return a.name < b.name
    end)
end

function file_dialog.scan_directory_love(dialog)
    table.insert(dialog.files, {name = "LFS not available - limited browsing", type = "error"})
    
    local success, items = pcall(love.filesystem.getDirectoryItems, ".")
    if success and items then
        for _, item in ipairs(items) do
            local info = love.filesystem.getInfo(item)
            if info then
                table.insert(dialog.files, {name = item, type = info.type})
            end
        end
    end
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
    elseif key == "backspace" and lfs then
        file_dialog.go_parent(dialog)
        return true
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
    if dialog.selected_index > #dialog.files then return false end
    
    local item = dialog.files[dialog.selected_index]
    
    if item.type == "drive" and lfs then
        dialog.current_dir = item.name .. "\\"
        file_dialog.scan_directory(dialog)
        dialog.selected_index = 1
        return true
    elseif item.type == "directory" then
        if item.name == ".." and lfs then
            file_dialog.go_parent(dialog)
        elseif lfs then
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
        local full_path
        if lfs then
            full_path = dialog.current_dir .. "/" .. item.name
            if love.system.getOS() == "Windows" then
                full_path = dialog.current_dir .. "\\" .. item.name
            end
            
            local file = io.open(full_path, "r")
            if file then
                local content = file:read("*all")
                file:close()
                
                buffer.lines = {}
                for line in content:gmatch("[^\r\n]*") do
                    table.insert(buffer.lines, line)
                end
                if #buffer.lines == 0 then
                    table.insert(buffer.lines, "")
                end
                buffer.filepath = full_path
                buffer.dirty = false
            end
        else
            local success, content = pcall(love.filesystem.read, item.name)
            if success then
                buffer.lines = {}
                for line in content:gmatch("[^\r\n]*") do
                    table.insert(buffer.lines, line)
                end
                if #buffer.lines == 0 then
                    table.insert(buffer.lines, "")
                end
                buffer.filepath = item.name
                buffer.dirty = false
            end
        end
        
        dialog.active = false
        return true
    end
    return false
end

return file_dialog