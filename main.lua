local project = require("project")
local spotlight = require("spotlight")

local lines = {""}
local cursor_line = 1
local cursor_col = 0
local available_projects = {}
local current_project = nil

function love.textinput(t)
        if spotlight.is_open then
        spotlight.handle_input(t)
        if spotlight.current_action == "Open Project" then
            local filtered = {}
            for _, proj in ipairs(available_projects) do
                if proj:lower():find(spotlight.search_text:lower(), 1, true) then
                    table.insert(filtered, project.get_project_name(proj))
                end
            end
            spotlight.set_items(filtered)
        end
        return
    end
    local line = lines[cursor_line]
    lines[cursor_line] = line:sub(1, cursor_col) .. t .. line:sub(cursor_col + 1)
    cursor_col = cursor_col + 1
end

function love.keypressed(key)
    if spotlight.is_open then
        if key == "escape" then
            spotlight.close()
            return
        elseif key == "return" then
            if spotlight.current_action == "Open Project" then
                local selected = spotlight.get_selected_item()
                if selected then
                    -- TODO: Actually open the project
                    print("Opening project:", selected)
                    spotlight.close()
                end
            end
            return
        elseif key == "up" then
            spotlight.move_selection(-1)
            return
        elseif key == "down" then
            spotlight.move_selection(1)
            return
        elseif key == "backspace" then
            spotlight.handle_backspace()
            if spotlight.current_action == "Open Project" then
                local filtered = {}
                for _, proj in ipairs(available_projects) do
                    if proj:lower():find(spotlight.search_text:lower(), 1, true) then
                        table.insert(filtered, project.get_project_name(proj))
                    end
                end
                spotlight.set_items(filtered)
            end
            return
        end
    else
        if key == "x" and (love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt")) then
            spotlight.open("Open Project")
            local project_names = {}
            for _, proj in ipairs(available_projects) do
                table.insert(project_names, project.get_project_name(proj))
            end
            spotlight.set_items(project_names)
            return
        end
    end
    if key == "backspace" then
        if cursor_col > 0 then
            local line = lines[cursor_line]
            lines[cursor_line] = line:sub(1, cursor_col - 1) .. line:sub(cursor_col + 1)
            cursor_col = cursor_col - 1
        elseif cursor_line > 1 then
            local current_line = lines[cursor_line]
            cursor_col = #lines[cursor_line - 1]
            lines[cursor_line - 1] = lines[cursor_line - 1] .. current_line
            table.remove(lines, cursor_line)
            cursor_line = cursor_line - 1
        end
    elseif key == "return" then
        local line = lines[cursor_line]
        local new_line = line:sub(cursor_col + 1)
        lines[cursor_line] = line:sub(1, cursor_col)
        table.insert(lines, cursor_line + 1, new_line)
        cursor_line = cursor_line + 1
        cursor_col = 0
    elseif key == "up" and cursor_line > 1 then
        cursor_line = cursor_line - 1
        cursor_col = math.min(cursor_col, #lines[cursor_line])
    elseif key == "down" and cursor_line < #lines then
        cursor_line = cursor_line + 1
        cursor_col = math.min(cursor_col, #lines[cursor_line])
    elseif key == "left" and cursor_col > 0 then
        cursor_col = cursor_col - 1
    elseif key == "right" and cursor_col < #lines[cursor_line] then
        cursor_col = cursor_col + 1
    end
end

function love.load()
    love.window.setTitle("Natura Editor")
    love.window.setMode(800, 600)
    
    available_projects = project.scan_projects()
end

function love.draw()    
    for i, line in ipairs(lines) do
        love.graphics.print(line, 10, 30 + i * 20)
    end
    local font = love.graphics.getFont()
    local text_before_cursor = lines[cursor_line]:sub(1, cursor_col)
    local cursor_x = 10 + font:getWidth(text_before_cursor)
    local cursor_y = 30 + cursor_line * 20
    love.graphics.line(cursor_x, cursor_y, cursor_x, cursor_y + font:getHeight())
    
    spotlight.draw()
end