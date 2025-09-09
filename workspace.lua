local workspace = {}

workspace.current_files = {}
workspace.current_directories = {}

function workspace.scan_directory(path)
    local files = {}
    local directories = {}
    
    local function scan_recursive(dir_path, relative_path)
        local info = love.filesystem.getInfo(dir_path)
        if not info or info.type ~= "directory" then
            return
        end
        
        local items = love.filesystem.getDirectoryItems(dir_path)
        for _, item in ipairs(items) do
            local full_path = dir_path .. "/" .. item
            local rel_path = relative_path and (relative_path .. "/" .. item) or item
            local item_info = love.filesystem.getInfo(full_path)
            
            if item_info then
                if item_info.type == "file" then
                    table.insert(files, {
                        name = item,
                        path = full_path,
                        relative_path = rel_path
                    })
                elseif item_info.type == "directory" then
                    table.insert(directories, {
                        name = item,
                        path = full_path,
                        relative_path = rel_path
                    })
                    scan_recursive(full_path, rel_path)
                end
            end
        end
    end
    
    scan_recursive(path, nil)
    return files, directories
end

function workspace.load_from_config(config)
    workspace.current_files = {}
    workspace.current_directories = {}
    
    if not config or not config.workspace then
        return
    end
    
    for _, workspace_path in ipairs(config.workspace) do
        local files, dirs = workspace.scan_directory(workspace_path)
        for _, file in ipairs(files) do
            table.insert(workspace.current_files, file)
        end
        for _, dir in ipairs(dirs) do
            table.insert(workspace.current_directories, dir)
        end
    end
end

function workspace.get_files()
    return workspace.current_files
end

function workspace.get_directories()
    return workspace.current_directories
end

return workspace