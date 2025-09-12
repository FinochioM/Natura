local config = {}
package.cpath = package.cpath .. ";a:/Desarrollos/Natura/libs/?.dll"
local lfs = require("lfs")

local function get_default_config()
    return {
        tab_size = 4,
        indent_using = "spaces",
        window_width = 800,
        window_height = 600,
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
            ["escape"] = "clear_selection"
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
# You can modify any setting here.

# Editor Settings
indent_using: spaces
tab_size: 4
window_width: 800
window_height: 600

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
    
    if write_file("natura.config", content) then
        print("Config saved to natura.config")
    else
        print("Failed to save config file")
    end
end

return config