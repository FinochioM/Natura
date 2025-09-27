local goto_module = {}
local editor = require("editor")

function goto_module.create()
    return {
        active = false,
        input = ""
    }
end

function goto_module.toggle(goto_state)
    goto_state.active = not goto_state.active
    if goto_state.active then
        goto_state.input = ""
    end
end

function goto_module.handle_input(goto_state, text)
    if not goto_state.active then return end
    
    if string.match(text, "%d") then
        goto_state.input = goto_state.input .. text
    end
end

function goto_module.handle_key(goto_state, key, ed, buf)
    local config = require("config")
    
    if key == "return" or key == "kpenter" then
        local line_num = tonumber(goto_state.input)
        if line_num and line_num >= 1 and line_num <= #buf.lines then
            ed.cursor_line = line_num
            ed.cursor_col = 0
            editor.clear_selection(ed)
            editor.update_viewport(ed, buf)
        end
        goto_state.active = false
        goto_state.input = ""
        return true
    elseif key == "backspace" then
        if #goto_state.input > 0 then
            goto_state.input = goto_state.input:sub(1, -2)
        end
        return true
    elseif key == "escape" then
        if config.get("can_cancel_go_to_line") then
            goto_state.active = false
            goto_state.input = ""
            return true
        else
            return true
        end
    end
    
    return false
end

function goto_module.draw(goto_state)
    if not goto_state.active then return end
    
    local window_width = love.graphics.getWidth()
    local bar_width = 300
    local bar_height = 25
    local bar_x = window_width - bar_width - 10
    local bar_y = 10
    
    love.graphics.setColor(0.2, 0.2, 0.2, 0.9)
    love.graphics.rectangle("fill", bar_x, bar_y, bar_width, bar_height)
    
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.rectangle("line", bar_x, bar_y, bar_width, bar_height)
    
    love.graphics.setColor(1, 1, 1)
    local text = "Go to line: " .. goto_state.input
    
    local config = require("config")
    if not config.get("can_cancel_go_to_line") then
        text = text .. " (Enter to confirm)"
    else
        text = text .. " (Enter/Esc)"
    end
    
    love.graphics.print(text, bar_x + 5, bar_y + 5)
end

function goto_module.execute(goto_state, editor, buffer)
    if not goto_state.active or goto_state.input == "" then return end
    
    local line_num = tonumber(goto_state.input)
    if line_num and line_num >= 1 and line_num <= #buffer.lines then
        editor.cursor_line = line_num
        editor.cursor_col = 0
        require("editor").update_viewport(editor, buffer)
    end
    
    goto_state.active = false
    goto_state.input = ""
end

return goto_module