local actions_menu = {}

function actions_menu.create()
    return {
        active = false,
        actions = {},
        selected_index = 1,
        input = ""
    }
end

function actions_menu.get_available_actions()
    return {
        {
            name = "Open File",
            description = "Open a file from disk",
            action = function(editor, buffer)
                local file_dialog = require("file_dialog")
                file_dialog.toggle(editor.file_dialog)
            end
        },
        {
            name = "Open Global Config",
            description = "Open the global configuration file",
            action = function(editor, buffer)
                local config_path = "natura.config"
                if love.filesystem.getInfo(config_path) then
                    local buffer_module = require("buffer")
                    buffer_module.load_file(buffer, config_path)
                    print("Opened global config: " .. config_path)
                else
                    print("Global config file not found: " .. config_path)
                end
            end
        },
        {
            name = "New File",
            description = "Create a new empty file",
            action = function(editor, buffer)
                local buffer_module = require("buffer")
                buffer_module.create_new_file(buffer)
                editor.cursor_line = 1
                editor.cursor_col = 0
                require("editor").clear_selection(editor)
                require("editor").update_viewport(editor, buffer)
            end
        }
    }
end

function actions_menu.toggle(menu)
    menu.active = not menu.active
    if menu.active then
        menu.input = ""
        menu.selected_index = 1
        actions_menu.filter_actions(menu)
    end
end

function actions_menu.filter_actions(menu)
    local all_actions = actions_menu.get_available_actions()
    menu.actions = {}
    
    local filter = menu.input:lower()
    
    for _, action in ipairs(all_actions) do
        if filter == "" or action.name:lower():find(filter, 1, true) or 
           action.description:lower():find(filter, 1, true) then
            table.insert(menu.actions, action)
        end
    end
    
    if menu.selected_index > #menu.actions then
        menu.selected_index = math.max(1, #menu.actions)
    end
end

function actions_menu.move_selection_up(menu)
    if #menu.actions > 0 then
        menu.selected_index = menu.selected_index - 1
        if menu.selected_index < 1 then
            menu.selected_index = #menu.actions
        end
    end
end

function actions_menu.move_selection_down(menu)
    if #menu.actions > 0 then
        menu.selected_index = menu.selected_index + 1
        if menu.selected_index > #menu.actions then
            menu.selected_index = 1
        end
    end
end

function actions_menu.execute_selected(menu, editor, buffer)
    if #menu.actions > 0 and menu.selected_index >= 1 and menu.selected_index <= #menu.actions then
        local selected_action = menu.actions[menu.selected_index]
        menu.active = false
        selected_action.action(editor, buffer)
        return true
    end
    return false
end

function actions_menu.handle_text(menu, text)
    menu.input = menu.input .. text
    actions_menu.filter_actions(menu)
end

function actions_menu.handle_key(menu, key, editor, buffer)
    if key == "escape" then
        menu.active = false
        return true
    elseif key == "return" then
        return actions_menu.execute_selected(menu, editor, buffer)
    elseif key == "up" then
        actions_menu.move_selection_up(menu)
        return true
    elseif key == "down" then
        actions_menu.move_selection_down(menu)
        return true
    elseif key == "backspace" then
        if #menu.input > 0 then
            menu.input = menu.input:sub(1, -2)
            actions_menu.filter_actions(menu)
        end
        return true
    end
    return false
end

function actions_menu.draw(menu)
    if not menu.active then return end
    
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
    love.graphics.print("Actions", dialog_x + 10, dialog_y + 10)
    
    colors.set_color("text_dim")
    love.graphics.print("Filter: " .. menu.input, dialog_x + 10, dialog_y + 30)
    
    local font = love.graphics.getFont()
    local line_height = font:getHeight()
    local list_start_y = dialog_y + 60
    local visible_items = math.floor((dialog_height - 80) / (line_height * 2)) -- 2 lines per action
    
    for i = 1, math.min(#menu.actions, visible_items) do
        local action = menu.actions[i]
        local y = list_start_y + (i - 1) * line_height * 2
        
        if i == menu.selected_index then
            colors.set_color("selection_active")
            love.graphics.rectangle("fill", dialog_x + 5, y - 2, dialog_width - 10, line_height * 2)
        end
        
        colors.set_color("text")
        love.graphics.print(action.name, dialog_x + 10, y)
        
        colors.set_color("text_dim")
        love.graphics.print(action.description, dialog_x + 15, y + line_height)
    end
    
    colors.set_color("text_dim")
    local status_text = string.format("%d actions", #menu.actions)
    love.graphics.print(status_text, dialog_x + 10, dialog_y + dialog_height - 25)
end

return actions_menu