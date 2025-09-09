local config_parser = require("config_parser")
local workspace = require("workspace")

local project = {}

project.current_config = nil
project.current_name = nil

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

function project.open_project(filename)
    local filepath = "projects/" .. filename
    local config = config_parser.parse_project_file(filepath)
    
    if config then
        project.current_config = config
        project.current_name = project.get_project_name(filename)
        workspace.load_from_config(config)
        return true
    end
    
    return false
end

function project.get_current_project()
    return project.current_name
end

function project.get_current_config()
    return project.current_config
end

return project