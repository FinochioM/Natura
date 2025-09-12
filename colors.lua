local colors = {}

local default_colors = {
    background = {0.1, 0.1, 0.1, 1.0},
    background_dark = {0.08, 0.08, 0.08, 1.0},
    
    text = {1.0, 1.0, 1.0, 1.0},
    text_dim = {0.6, 0.6, 0.6, 1.0},
    
    cursor = {0.8, 0.8, 0.8, 1.0},
    cursor_inactive = {0.5, 0.5, 0.5, 1.0},
    
    selection_active = {0.3, 0.4, 0.6, 0.8},
    selection_inactive = {0.2, 0.2, 0.3, 0.6},
    
    search_result_active = {0.8, 0.6, 0.2, 0.8},
    search_result_inactive = {0.6, 0.4, 0.1, 0.6},
    
    code_default = {1.0, 1.0, 1.0, 1.0},
    code_comment = {0.5, 0.7, 0.5, 1.0},
    code_string_literal = {0.8, 0.6, 0.4, 1.0},
    code_keyword = {0.6, 0.8, 1.0, 1.0},
    code_function = {0.7, 0.9, 0.7, 1.0},
    code_type = {0.9, 0.7, 0.6, 1.0},
    
    ui_default = {0.8, 0.8, 0.8, 1.0},
    ui_dim = {0.6, 0.6, 0.6, 1.0},
    ui_error = {1.0, 0.4, 0.4, 1.0},
    ui_warning = {1.0, 0.8, 0.3, 1.0},
    ui_success = {0.4, 0.8, 0.4, 1.0},
}

local current_colors = {}

function colors.load()
    local config = require("config")
    
    for name, color in pairs(default_colors) do
        current_colors[name] = {color[1], color[2], color[3], color[4]}
    end
    
    local user_colors = config.get("colors") or {}
    for name, hex in pairs(user_colors) do
        local color = colors.hex_to_rgba(hex)
        if color then
            current_colors[name] = color
            print("Loaded color: " .. name .. " = " .. hex)
        end
    end
end

function colors.get(name)
    return current_colors[name] or default_colors[name] or {1, 1, 1, 1}
end

function colors.hex_to_rgba(hex)
    if type(hex) ~= "string" or #hex ~= 8 then
        print("Invalid hex color: " .. tostring(hex))
        return nil
    end
    
    local r = tonumber(hex:sub(1, 2), 16) / 255.0
    local g = tonumber(hex:sub(3, 4), 16) / 255.0  
    local b = tonumber(hex:sub(5, 6), 16) / 255.0
    local a = tonumber(hex:sub(7, 8), 16) / 255.0
    
    if not r or not g or not b or not a then
        print("Failed to parse hex color: " .. hex)
        return nil
    end
    
    return {r, g, b, a}
end

function colors.set_color(name)
    local color = colors.get(name)
    love.graphics.setColor(color[1], color[2], color[3], color[4])
end

return colors