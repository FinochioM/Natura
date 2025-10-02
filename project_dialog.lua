local project_dialog = {}

local active = false
local projects = {}
local selected_index = 1
local filter_text = ""

local function scan_projects()
    projects = {}
    local lfs = require("lfs")
    
    for file in lfs.dir("projects") do
        if file:match("%.natura%-project$") then
            table.insert(projects, file)
        end
    end
    
    table.sort(projects)
end

function project_dialog.toggle(editor)
    active = not active
    if active then
        scan_projects()
        selected_index = 1
        filter_text = ""
    end
end

function project_dialog.is_active()
    return active
end

function project_dialog.handle_key(key)
    if key == "escape" then
        active = false
        return true
    elseif key == "return" then
        if #projects > 0 and selected_index >= 1 and selected_index <= #projects then
            local project_path = "projects/" .. projects[selected_index]
            local project_module = require("project")
            project_module.load(project_path)
            active = false
        end
        return true
    elseif key == "up" then
        if #projects > 0 then
            selected_index = selected_index - 1
            if selected_index < 1 then
                selected_index = #projects
            end
        end
        return true
    elseif key == "down" then
        if #projects > 0 then
            selected_index = selected_index + 1
            if selected_index > #projects then
                selected_index = 1
            end
        end
        return true
    end
    return false
end

function project_dialog.draw()
    if not active then return end
    
    local window_width = love.graphics.getWidth()
    local window_height = love.graphics.getHeight()
    local dialog_width = 500
    local dialog_height = 400
    local dialog_x = (window_width - dialog_width) / 2
    local dialog_y = (window_height - dialog_height) / 2
    
    local colors = require("colors")
    colors.set_color("background_dark")
    love.graphics.rectangle("fill", dialog_x, dialog_y, dialog_width, dialog_height)
    
    colors.set_color("ui_dim")
    love.graphics.rectangle("line", dialog_x, dialog_y, dialog_width, dialog_height)
    
    colors.set_color("text")
    love.graphics.print("Switch To Project", dialog_x + 10, dialog_y + 10)
    
    local font = love.graphics.getFont()
    local line_height = font:getHeight()
    local list_start_y = dialog_y + 40
    
    if #projects == 0 then
        colors.set_color("text_dim")
        love.graphics.print("No projects found in projects/ directory", dialog_x + 10, list_start_y)
    else
        local visible_items = math.floor((dialog_height - 60) / line_height)
        
        for i = 1, math.min(#projects, visible_items) do
            local y = list_start_y + (i - 1) * line_height
            
            if i == selected_index then
                colors.set_color("selection_active")
                love.graphics.rectangle("fill", dialog_x + 5, y - 2, dialog_width - 10, line_height)
            end
            
            colors.set_color("text")
            love.graphics.print(projects[i], dialog_x + 10, y)
        end
    end
    
    colors.set_color("text_dim")
    local status = string.format("%d projects", #projects)
    love.graphics.print(status, dialog_x + 10, dialog_y + dialog_height - 25)
end

return project_dialog