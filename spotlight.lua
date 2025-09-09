-- spotlight.lua
local spotlight = {}

spotlight.is_open = false
spotlight.current_action = ""
spotlight.search_text = ""
spotlight.items = {}
spotlight.selected_index = 1
spotlight.current_path = ""
spotlight.path_history = {}

function spotlight.get_drives()
    local drives = {}
    local os_name = love.system.getOS()
    
    if os_name == "Windows" then
        -- Try common Windows drives
        local common_drives = {"C:", "D:", "E:", "F:", "G:", "H:"}
        for _, drive in ipairs(common_drives) do
            local success, result = pcall(love.filesystem.getDirectoryItems, drive .. "/")
            if success then
                table.insert(drives, drive .. "/")
            end
        end
    else
        -- Unix-like systems start from root
        table.insert(drives, "/")
    end
    
    return drives
end

function spotlight.get_system_directory_items(path)
    local items = {}
    local success, result = pcall(love.filesystem.getDirectoryItems, path)
    
    if success then
        local dirs = {}
        local files = {}
        
        for _, item in ipairs(result) do
            local full_path = path .. "/" .. item
            -- Try to determine if it's a directory by attempting to list it
            local is_dir_success = pcall(love.filesystem.getDirectoryItems, full_path)
            if is_dir_success then
                table.insert(dirs, item .. "/")
            else
                table.insert(files, item)
            end
        end
        
        -- Add directories first, then files
        for _, dir in ipairs(dirs) do
            table.insert(items, dir)
        end
        for _, file in ipairs(files) do
            table.insert(items, file)
        end
    end
    
    return items
end

function spotlight.open(action)
    spotlight.is_open = true
    spotlight.current_action = action or ""
    spotlight.search_text = ""
    spotlight.selected_index = 1
    spotlight.items = {}
    spotlight.current_path = ""
    spotlight.path_history = {}
end

function spotlight.close()
    spotlight.is_open = false
    spotlight.current_action = ""
    spotlight.search_text = ""
    spotlight.items = {}
    spotlight.selected_index = 1
    spotlight.current_path = ""
    spotlight.path_history = {}
end

function spotlight.set_items(items)
    spotlight.items = items
    spotlight.selected_index = math.min(spotlight.selected_index, #items)
    if spotlight.selected_index == 0 and #items > 0 then
        spotlight.selected_index = 1
    end
end

function spotlight.set_path(path)
    spotlight.current_path = path
    spotlight.search_text = ""
    spotlight.selected_index = 1
end

function spotlight.navigate_to_directory(dir_path)
    table.insert(spotlight.path_history, spotlight.current_path)
    spotlight.set_path(dir_path)
    
    local items = {}
    
    -- Add back navigation if not at root
    if dir_path ~= "" then
        table.insert(items, "../")
    end
    
    if spotlight.current_action == "Open Global File" then
        if dir_path == "" then
            -- Show drives at root level
            local drives = spotlight.get_drives()
            for _, drive in ipairs(drives) do
                table.insert(items, drive)
            end
        else
            -- Show directory contents
            local dir_items = spotlight.get_system_directory_items(dir_path)
            for _, item in ipairs(dir_items) do
                table.insert(items, item)
            end
        end
    else
        -- Regular love.filesystem navigation for project files
        local info = love.filesystem.getInfo(dir_path)
        if info and info.type == "directory" then
            local dir_items = love.filesystem.getDirectoryItems(dir_path)
            
            -- Add directories first
            for _, item in ipairs(dir_items) do
                local item_path = dir_path == "" and item or (dir_path .. "/" .. item)
                local item_info = love.filesystem.getInfo(item_path)
                if item_info and item_info.type == "directory" then
                    table.insert(items, item .. "/")
                end
            end
            
            -- Then add files
            for _, item in ipairs(dir_items) do
                local item_path = dir_path == "" and item or (dir_path .. "/" .. item)
                local item_info = love.filesystem.getInfo(item_path)
                if item_info and item_info.type == "file" then
                    table.insert(items, item)
                end
            end
        end
    end
    
    spotlight.set_items(items)
end

function spotlight.go_back()
    if #spotlight.path_history > 0 then
        local previous_path = table.remove(spotlight.path_history)
        spotlight.set_path(previous_path)
        spotlight.navigate_to_directory(previous_path)
    end
end

function spotlight.handle_input(text)
    spotlight.search_text = spotlight.search_text .. text
end

function spotlight.handle_backspace()
    if #spotlight.search_text > 0 then
        spotlight.search_text = spotlight.search_text:sub(1, -2)
    end
end

function spotlight.move_selection(direction)
    if #spotlight.items == 0 then return end
    
    spotlight.selected_index = spotlight.selected_index + direction
    if spotlight.selected_index < 1 then
        spotlight.selected_index = #spotlight.items
    elseif spotlight.selected_index > #spotlight.items then
        spotlight.selected_index = 1
    end
end

function spotlight.get_selected_item()
    if spotlight.selected_index > 0 and spotlight.selected_index <= #spotlight.items then
        return spotlight.items[spotlight.selected_index]
    end
    return nil
end

function spotlight.get_selected_full_path()
    local selected = spotlight.get_selected_item()
    if selected then
        if spotlight.current_path == "" then
            return selected
        else
            return spotlight.current_path .. "/" .. selected
        end
    end
    return nil
end

function spotlight.draw()
    if not spotlight.is_open then return end
    
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    
    -- Semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, width, height)
    
    -- Spotlight box
    local box_width = 600
    local box_x = (width - box_width) / 2
    local box_y = 100
    local box_height = 80 + #spotlight.items * 25 + 20
    
    love.graphics.setColor(0.2, 0.2, 0.2, 1)
    love.graphics.rectangle("fill", box_x, box_y, box_width, box_height)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", box_x, box_y, box_width, box_height)
    
    -- Action and search text
    love.graphics.setColor(1, 1, 1, 1)
    local display_text = spotlight.current_action .. ": " .. spotlight.search_text
    love.graphics.print(display_text, box_x + 10, box_y + 10)
    
    -- Current path
    if spotlight.current_path ~= "" then
        love.graphics.setColor(0.7, 0.7, 0.7, 1)
        love.graphics.print("Path: " .. spotlight.current_path, box_x + 10, box_y + 30)
    end
    
    -- Items list
    local list_start_y = box_y + (spotlight.current_path ~= "" and 55 or 35)
    for i, item in ipairs(spotlight.items) do
        local item_y = list_start_y + (i - 1) * 25
        if i == spotlight.selected_index then
            love.graphics.setColor(0.3, 0.5, 0.8, 1)
            love.graphics.rectangle("fill", box_x + 5, item_y, box_width - 10, 22)
        end
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(item, box_x + 10, item_y + 2)
    end
end

return spotlight