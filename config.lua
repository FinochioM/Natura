local config = {}
package.cpath = package.cpath .. ";a:/Desarrollos/Natura/libs/?.dll"
local lfs = require("lfs")

local default_config = {
    tab_size = 4,
    indent_using = "spaces", -- "spaces" or "tabs"
    window_width = 800,
    window_height = 600
}

local current_config = {}

for k, v in pairs(default_config) do
    current_config[k] = v
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
                        
                        if value == "true" then
                            current_config[key] = true
                        elseif value == "false" then
                            current_config[key] = false
                        elseif tonumber(value) then
                            current_config[key] = tonumber(value)
                        else
                            current_config[key] = value
                        end
                        
                        print("Loaded config: " .. key .. " = " .. tostring(current_config[key]))
                    end
                end
            end
        end
    else
        config.save()
    end
end

function config.save()
    local content = "# Natura Editor Configuration\n\n"
    
    for key, value in pairs(current_config) do
        content = content .. key .. ": " .. tostring(value) .. "\n"
    end
    
    if write_file("natura.config", content) then
        print("Config saved to natura.config")
    else
        print("Failed to save config file")
    end
end

return config