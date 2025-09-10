local file_dialog = {}

function file_dialog.create()
    return {
        active = false,
        current_dir = love.filesystem.getWorkingDirectory(),
        files = {},
        selected_index = 1,
        input = ""
    }
end

function file_dialog.toggle(dialog)
    dialog.active = not dialog.active
    if dialog.active then
        file_dialog.scan_directory(dialog)
        dialog.input = ""
        dialog.selected_index = 1
    end
end

function file_dialog.scan_directory(dialog)
    dialog.files = {}
    local items = love.filesystem.getDirectoryItems(".")
    
    table.insert(dialog.files, {name = "..", type = "directory"})
    
    for _, item in ipairs(items) do
        local info = love.filesystem.getInfo(item)
        if info and info.type == "directory" then
            table.insert(dialog.files, {name = item, type = "directory"})
        end
    end
    
    for _, item in ipairs(items) do
        local info = love.filesystem.getInfo(item)
        if info and info.type == "file" then
            table.insert(dialog.files, {name = item, type = "file"})
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
    end
    return false
end

function file_dialog.select_item(dialog, editor, buffer)
    if dialog.selected_index > #dialog.files then return false end
    
    local item = dialog.files[dialog.selected_index]
    if item.type == "directory" then
        if item.name == ".." then
            love.filesystem.setWorkingDirectory("..")
        else
            love.filesystem.setWorkingDirectory(item.name)
        end
        file_dialog.scan_directory(dialog)
        dialog.selected_index = 1
        return true
    else
        require("buffer").load_file(buffer, item.name)
        dialog.active = false
        return true
    end
end

return file_dialog