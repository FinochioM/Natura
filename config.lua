local config = {}
package.cpath = package.cpath .. ";a:/Desarrollos/Natura/libs/?.dll"
local lfs = require("lfs")

local default_config = {
    tab_size = 4,
    indent_using = "spaces",
    window_width = 800,
    window_height = 600,
    keybinds = {}
}

local current_config = {}

for k, v in pairs(default_config) do
    if type(v) == "table" then
        current_config[k] = {}
        for k2, v2 in pairs(v) do
            current_config[k][k2] = v2
        end
    else
        current_config[k] = v
    end
end

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

function config.load()
    local config_path = "natura.config"
    
    if file_exists(config_path) then
        local file_content = read_file(config_path)
        if file_content then
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
        end
        
        local keymap = require("keymap")
        keymap.load_keybinds()
    else
        config.save()
    end
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