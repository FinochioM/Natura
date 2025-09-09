local project = {}

function project.scan_projects()
    local projects = {}
    local info = love.filesystem.getInfo("projects")
    
    if not info or info.type ~= "directory" then
        love.filesystem.createDirectory("projects")
        return projects
    end
    
    local files = love.filesystem.getDirectoryItems("projects")
    for _, file in ipairs(files) do
        if file:match("%.natura$") then
            table.insert(projects, file)
        end
    end
    
    return projects
end

function project.get_project_name(filename)
    return filename:match("(.+)%.natura$") or filename
end

return project