local goto_module = {}

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