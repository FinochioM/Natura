local spotlight = {}

spotlight.is_open = false
spotlight.current_action = ""
spotlight.search_text = ""
spotlight.items = {}
spotlight.selected_index = 1

function spotlight.open(action)
    spotlight.is_open = true
    spotlight.current_action = action or ""
    spotlight.search_text = ""
    spotlight.selected_index = 1
    spotlight.items = {}
end

function spotlight.close()
    spotlight.is_open = false
    spotlight.current_action = ""
    spotlight.search_text = ""
    spotlight.items = {}
    spotlight.selected_index = 1
end

function spotlight.set_items(items)
    spotlight.items = items
    spotlight.selected_index = math.min(spotlight.selected_index, #items)
    if spotlight.selected_index == 0 and #items > 0 then
        spotlight.selected_index = 1
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

function spotlight.draw()
    if not spotlight.is_open then return end
    
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, width, height)
    
    local box_width = 600
    local box_x = (width - box_width) / 2
    local box_y = 100
    local box_height = 40 + #spotlight.items * 25 + 20
    
    love.graphics.setColor(0.2, 0.2, 0.2, 1)
    love.graphics.rectangle("fill", box_x, box_y, box_width, box_height)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", box_x, box_y, box_width, box_height)
    
    love.graphics.setColor(1, 1, 1, 1)
    local display_text = spotlight.current_action .. ": " .. spotlight.search_text
    love.graphics.print(display_text, box_x + 10, box_y + 10)
    
    for i, item in ipairs(spotlight.items) do
        local item_y = box_y + 40 + (i - 1) * 25
        if i == spotlight.selected_index then
            love.graphics.setColor(0.3, 0.5, 0.8, 1)
            love.graphics.rectangle("fill", box_x + 5, item_y, box_width - 10, 22)
        end
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(item, box_x + 10, item_y + 2)
    end
end

return spotlight