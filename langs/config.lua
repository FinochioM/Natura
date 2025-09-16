local config_lang = {}

local TOKEN_TYPES = {
    COMMENT = "comment",
    SECTION_HEADER = "section_header", 
    COLOR_KEY = "color_key",
    KEYBIND_KEY = "keybind_key", 
    SETTING_KEY = "setting_key",
    SEPARATOR = "separator",
    HEX_VALUE = "hex_value",
    ACTION_VALUE = "action_value",
    STRING_VALUE = "string_value",
    NUMBER_VALUE = "number_value",
    DEFAULT = "default"
}

local function is_digit(char)
    return char >= "0" and char <= "9"
end

local function is_hex_digit(char)
    return (char >= "0" and char <= "9") or 
           (char >= "a" and char <= "f") or 
           (char >= "A" and char <= "F")
end

local function is_alpha(char)
    return (char >= "a" and char <= "z") or (char >= "A" and char <= "Z")
end

local function is_alnum(char)
    return is_alpha(char) or is_digit(char)
end

local KNOWN_ACTIONS = {
    save = true,
    search = true,
    goto_line = true,
    copy = true,
    paste = true,
    cut = true,
    select_all = true,
    select_word = true,
    open_file = true,
    undo = true,
    redo = true,
    delete_to_line_end = true,
    delete_to_line_start = true,
    delete_word_left = true,
    delete_word_right = true,
    duplicate_lines = true,
    toggle_comment = true,
    find_next = true,
    find_previous = true,
    move_lines_up = true,
    move_lines_down = true,
    tab_or_indent = true,
    unindent = true,
    file_start = true,
    file_end = true,
    word_left = true,
    word_right = true,
    line_start = true,
    line_end = true,
    delete_line = true,
    clear_selection = true,
    show_actions = true
}

function config_lang.tokenize(text)
    local tokens = {}
    local lines = {}
    
    for line in text:gmatch("([^\n]*)\n?") do
        table.insert(lines, line)
    end
    
    local current_pos = 1
    
    for line_num, line in ipairs(lines) do
        local line_start_pos = current_pos
        local trimmed = line:gsub("^%s*", ""):gsub("%s*$", "")
        
        if trimmed == "" then
            current_pos = current_pos + #line + 1
        elseif trimmed:sub(1, 1) == "#" then
            local comment_type = TOKEN_TYPES.COMMENT
            
            if trimmed:match("^# [A-Z]") then
                comment_type = TOKEN_TYPES.SECTION_HEADER
            end
            
            table.insert(tokens, {
                type = comment_type,
                start = current_pos,
                length = #line
            })
            current_pos = current_pos + #line + 1
        else
            local key, value = line:match("^%s*([^:]+):%s*(.*)$")
            if key and value then
                key = key:gsub("%s+$", "") -- trim right
                value = value:gsub("^%s+", "") -- trim left
                
                local key_start = line:find(key, 1, true)
                local colon_pos = line:find(":", key_start + #key, true)
                local value_start = line:find(value, colon_pos + 1, true)
                
                if key_start and colon_pos and value_start then
                    local key_type = TOKEN_TYPES.SETTING_KEY
                    if key:match("^colors%.") then
                        key_type = TOKEN_TYPES.COLOR_KEY
                    elseif key:match("^keybinds%.") then
                        key_type = TOKEN_TYPES.KEYBIND_KEY
                    end
                    
                    table.insert(tokens, {
                        type = key_type,
                        start = current_pos + key_start - 1,
                        length = #key
                    })
                    
                    table.insert(tokens, {
                        type = TOKEN_TYPES.SEPARATOR,
                        start = current_pos + colon_pos - 1,
                        length = 1
                    })
                    
                    local value_type = TOKEN_TYPES.STRING_VALUE
                    if value:match("^[0-9A-Fa-f]+$") and #value >= 6 and #value <= 8 then
                        value_type = TOKEN_TYPES.HEX_VALUE
                    elseif KNOWN_ACTIONS[value] then
                        value_type = TOKEN_TYPES.ACTION_VALUE
                    elseif value:match("^%d+$") then
                        value_type = TOKEN_TYPES.NUMBER_VALUE
                    end
                    
                    table.insert(tokens, {
                        type = value_type,
                        start = current_pos + value_start - 1,
                        length = #value
                    })
                end
            else
                table.insert(tokens, {
                    type = TOKEN_TYPES.DEFAULT,
                    start = current_pos,
                    length = #line
                })
            end
            
            current_pos = current_pos + #line + 1
        end
    end
    
    return tokens
end

return config_lang