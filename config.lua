local config = {}
package.cpath = package.cpath .. ";a:/Desarrollos/Natura/libs/?.dll"
local lfs = require("lfs")

local function get_default_config()
    return {
        tab_size = 4,
        indent_using = "spaces",
        window_width = 800,
        window_height = 600,
        font = "extras/fonts/FiraCode-Retina.ttf",
        font_size = 14,
        maximize_on_start = false,
        open_on_the_biggest_monitor = false,
        cursor_as_block = true,
        cursor_blink_time_in_seconds = 5,
        highlight_selection_occurrences = true,
        highlight_line_with_cursor = false,
        highlight_matching_brackets = false,
        show_paste_effect = true,
        smooth_scrolling = true,
        scroll_beyond_last_line = true,
        show_scrollbar_marks = true,
        scrollbar_width_scale = 1.0,
        scrollbar_min_opacity = 0.0,
        scrollbar_max_opacity = 1.0,
        scrollbar_fade_in_sensitivity = 10.0,
        scrollbar_fade_out_delay_seconds = 2.0,
        colors = {
            background = "222222FF",
            background_dark = "000000FF",
            background_light = "1C1C1CFF",
            line_highlight = "2A2A2AFF",
            
            text = "BFC9DBFF",
            text_dim = "87919DFF",
            
            cursor = "26B2B2FF",
            cursor_inactive = "196666FF",
            
            selection_active = "1C4449FF",
            selection_inactive = "1C44497F",
            selection_highlight = "599999FF",
            bracket_highlight = "E8FCFE30",
            paste_animation = "1C4449FF",
            
            search_result_active = "8E772EFF",
            search_result_inactive = "FCEDFC26",
            
            code_default = "BFC9DBFF",
            code_comment = "87919DFF",
            code_multiline_comment = "87919DFF",
            code_string_literal = "879899FF",
            code_multiline_string = "D4BC7DFF",
            code_raw_string = "D4BC7DFF",
            code_char_literal = "D4BC7DFF",
            code_identifier = "FFFFFFFF",
            code_number = "D699B5FF",
            code_keyword = "99449AFF",
            code_type = "739210FF",
            code_value = "C698D6FF",
            code_function = "00C1BBFF",
            code_builtin_function = "E0AD82FF",
            code_builtin_variable = "D699B5FF",
            code_operation = "E0AD82FF",
            code_punctuation = "BFC9DBFF",
            code_modifier = "E67D74FF",
            code_attribute = "E67D74FF",
            code_macro = "E0AD82FF",
            code_directive = "E67D74FF",
            
            ui_default = "BFC9DBFF",
            ui_dim = "87919DFF",
            ui_neutral = "4C4C4CFF",
            ui_error = "772222FF",
            ui_error_bright = "FF0000FF",
            ui_warning = "F8AD34FF",
            ui_warning_dim = "986032FF",
            ui_success = "227722FF",

            scrollbar = "33CCCC19",
            scrollbar_hover = "33CCCC4C", 
            scrollbar_background = "10191F4C",
        },
        keybinds = {
            ["ctrl+s"] = "save",
            ["ctrl+f"] = "search",
            ["ctrl+g"] = "goto_line",
            ["ctrl+c"] = "copy",
            ["ctrl+v"] = "paste",
            ["ctrl+x"] = "cut",
            ["ctrl+a"] = "select_all",
            ["ctrl+d"] = "select_word",
            ["ctrl+o"] = "open_file",
            ["ctrl+z"] = "undo",
            ["ctrl+y"] = "redo",
            ["ctrl+k"] = "delete_to_line_end",
            ["ctrl+u"] = "delete_to_line_start",
            ["ctrl+backspace"] = "delete_word_left",
            ["ctrl+delete"] = "delete_word_right",
            ["ctrl+shift+d"] = "duplicate_lines",
            ["ctrl+/"] = "toggle_comment",
            ["f3"] = "find_next",
            ["shift+f3"] = "find_previous",
            ["alt+up"] = "move_lines_up",
            ["alt+down"] = "move_lines_down",
            ["tab"] = "tab_or_indent",
            ["shift+tab"] = "unindent",
            ["ctrl+home"] = "file_start",
            ["ctrl+end"] = "file_end",
            ["ctrl+left"] = "word_left",
            ["ctrl+right"] = "word_right",
            ["home"] = "line_start",
            ["end"] = "line_end",
            ["shift+delete"] = "delete_line",
            ["escape"] = "clear_selection",
            ["alt+x"] = "show_actions",
        }
    }
end

local current_config = {}

function config.get(key)
    return current_config[key]
end

function config.set(key, value)
    current_config[key] = value
end

local function file_exists(path)
    local file = io.open(path, "r")
    if file then
        file:close()
        return true
    end
    return false
end

local function read_file(path)
    local file = io.open(path, "r")
    if file then
        local content = file:read("*all")
        file:close()
        return content
    end
    return nil
end

local function write_file(path, content)
    local file = io.open(path, "w")
    if file then
        file:write(content)
        file:close()
        return true
    end
    return false
end

function config.create_default_config()
    local content = [[# Natura Editor Configuration
# This file contains all settings and keybinds for Natura Editor.

# Editor Settings
indent_using: spaces
tab_size: 4
window_width: 800
window_height: 600

# Color Theme - modify these hex values (RRGGBBAA format)
colors.background: 1A1A1AFF
colors.background_dark: 141414FF
colors.text: FFFFFFFF
colors.text_dim: 999999FF
colors.cursor: CCCCCCFF
colors.cursor_inactive: 808080FF
colors.selection_active: 4D6699CC
colors.selection_inactive: 33334D99
colors.search_result_active: CC9933CC
colors.search_result_inactive: 99661A99
colors.code_default: FFFFFFFF
colors.code_comment: 7FCC7FFF
colors.code_string_literal: CC9966FF
colors.code_keyword: 99CCFFFF
colors.code_function: B3E6B3FF
colors.code_type: E6B399FF
colors.ui_default: CCCCCCFF
colors.ui_dim: 999999FF
colors.ui_error: FF6666FF
colors.ui_warning: FFCC4DFF
colors.ui_success: 66CC66FF

# Keybinds - modify these to customize your shortcuts
keybinds.ctrl+s: save
keybinds.ctrl+f: search
keybinds.ctrl+g: goto_line
keybinds.ctrl+c: copy
keybinds.ctrl+v: paste
keybinds.ctrl+x: cut
keybinds.ctrl+a: select_all
keybinds.ctrl+d: select_word
keybinds.ctrl+o: open_file
keybinds.ctrl+z: undo
keybinds.ctrl+y: redo
keybinds.ctrl+k: delete_to_line_end
keybinds.ctrl+u: delete_to_line_start
keybinds.ctrl+backspace: delete_word_left
keybinds.ctrl+delete: delete_word_right
keybinds.ctrl+shift+d: duplicate_lines
keybinds.ctrl+/: toggle_comment
keybinds.f3: find_next
keybinds.shift+f3: find_previous
keybinds.alt+up: move_lines_up
keybinds.alt+down: move_lines_down
keybinds.tab: tab_or_indent
keybinds.shift+tab: unindent
keybinds.ctrl+home: file_start
keybinds.ctrl+end: file_end
keybinds.ctrl+left: word_left
keybinds.ctrl+right: word_right
keybinds.home: line_start
keybinds.end: line_end
keybinds.shift+delete: delete_line
keybinds.escape: clear_selection
]]
    
    if write_file("natura.config", content) then
        print("Created default natura.config file")
        return true
    else
        print("ERROR: Could not create natura.config file!")
        return false
    end
end

function config.load()
    local config_path = "natura.config"
    
    current_config = get_default_config()
    
    if not file_exists(config_path) then
        print("No natura.config found, creating default config...")
        if not config.create_default_config() then
            error("FATAL: Could not create config file. Natura Editor requires a config file to run.")
        end
    end
    
    local file_content = read_file(config_path)
    if not file_content then
        error("FATAL: Could not read natura.config file.")
    end
    
    current_config.keybinds = {}
    
    for line in file_content:gmatch("[^\r\n]+") do
        line = line:match("^%s*(.-)%s*$") -- trim whitespace
        
        if line ~= "" and not line:match("^#") then -- skip empty lines and comments
            local key, value = line:match("^([^:]+):%s*(.+)$")
            if key and value then
                key = key:match("^%s*(.-)%s*$") -- trim key
                value = value:match("^%s*(.-)%s*$") -- trim value
                
                local main_key, sub_key = key:match("^([^%.]+)%.(.+)$")
                
                local final_value
                if value == "true" then
                    final_value = true
                elseif value == "false" then
                    final_value = false
                elseif tonumber(value) then
                    final_value = tonumber(value)
                else
                    final_value = value
                end
                
                if main_key and sub_key then
                    if not current_config[main_key] then
                        current_config[main_key] = {}
                    end
                    current_config[main_key][sub_key] = final_value
                    print("Loaded config: " .. main_key .. "." .. sub_key .. " = " .. tostring(final_value))
                else
                    current_config[key] = final_value
                    print("Loaded config: " .. key .. " = " .. tostring(final_value))
                end
            end
        end
    end
    
    if not current_config.keybinds or not next(current_config.keybinds) then
        error("FATAL: No keybinds found in config file. Please check your natura.config file.")
    end
    
    print("Config loaded successfully from natura.config")
end

function config.save()
    local content = "# Natura Editor Configuration\n\n"
    
    for key, value in pairs(current_config) do
        if type(value) == "table" then
            for sub_key, sub_value in pairs(value) do
                content = content .. key .. "." .. sub_key .. ": " .. tostring(sub_value) .. "\n"
            end
        else
            content = content .. key .. ": " .. tostring(value) .. "\n"
        end
    end
end

function config.reload()
    local config_path = "natura.config"
    
    if not file_exists(config_path) then
        return false
    end
    
    local file_content = read_file(config_path)
    if not file_content then
        return false
    end
    
    current_config = get_default_config()
    
    for line in file_content:gmatch("[^\r\n]+") do
        line = line:gsub("^%s+", ""):gsub("%s+$", "") -- trim
        
        if line:match("^#") or line == "" then
        elseif line:match("^colors%.") then
            local key, value = line:match("^colors%.([%w_]+):%s*(.+)")
            if key and value then
                current_config.colors[key] = value
            end
        elseif line:match("^keybinds%.") then
            local key, value = line:match("^keybinds%.([%w%+]+):%s*(.+)")
            if key and value then
                current_config.keybinds[key] = value
            end
        else
            local key, value = line:match("^([%w_]+):%s*(.+)")
            if key and value then
                local final_value
                if value == "true" then
                    final_value = true
                elseif value == "false" then
                    final_value = false
                elseif tonumber(value) then
                    final_value = tonumber(value)
                else
                    final_value = value
                end
                current_config[key] = final_value
            end
        end
    end
    
    return true
end

return config