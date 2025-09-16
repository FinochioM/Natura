local colors = {}

local current_colors = {}

local default_colors = { 
    background = {0.13, 0.13, 0.13, 1.0},           -- 222222FF
    background_dark = {0.0, 0.0, 0.0, 1.0},         -- 000000FF
    background_light = {0.11, 0.11, 0.11, 1.0},     -- 1C1C1CFF
    
    text = {0.75, 0.79, 0.86, 1.0},                  -- BFC9DBFF  
    text_dim = {0.53, 0.57, 0.62, 1.0},             -- 87919DFF
    
    cursor = {0.15, 0.70, 0.70, 1.0},               -- 26B2B2FF
    cursor_inactive = {0.10, 0.40, 0.40, 1.0},      -- 196666FF
    
    selection_active = {0.11, 0.27, 0.29, 1.0},     -- 1C4449FF
    selection_inactive = {0.11, 0.27, 0.29, 0.5},   -- 1C44497F
    
    search_result_active = {0.56, 0.47, 0.18, 1.0}, -- 8E772EFF
    search_result_inactive = {0.99, 0.93, 0.99, 0.15}, -- FCEDFC26
    
    code_default = {0.75, 0.79, 0.86, 1.0},         -- BFC9DBFF
    code_comment = {0.53, 0.57, 0.62, 1.0},         -- 87919DFF
    code_multiline_comment = {0.53, 0.57, 0.62, 1.0}, -- 87919DFF
    code_string_literal = {0.53, 0.60, 0.60, 1.0},  -- 879899FF
    code_multiline_string = {0.83, 0.74, 0.49, 1.0}, -- D4BC7DFF
    code_raw_string = {0.83, 0.74, 0.49, 1.0},      -- D4BC7DFF
    code_char_literal = {0.83, 0.74, 0.49, 1.0},    -- D4BC7DFF
    code_identifier = {1.0, 1.0, 1.0, 1.0},         -- FFFFFFFF
    code_number = {0.84, 0.60, 0.71, 1.0},          -- D699B5FF
    code_keyword = {0.60, 0.27, 0.60, 1.0},         -- 99449AFF
    code_type = {0.45, 0.57, 0.06, 1.0},            -- 739210FF
    code_value = {0.78, 0.60, 0.84, 1.0},           -- C698D6FF
    code_function = {0.0, 0.76, 0.73, 1.0},         -- 00C1BBFF
    code_builtin_function = {0.88, 0.68, 0.51, 1.0}, -- E0AD82FF
    code_builtin_variable = {0.84, 0.60, 0.71, 1.0}, -- D699B5FF
    code_operation = {0.88, 0.68, 0.51, 1.0},       -- E0AD82FF
    code_punctuation = {0.75, 0.79, 0.86, 1.0},     -- BFC9DBFF
    code_modifier = {0.90, 0.49, 0.45, 1.0},        -- E67D74FF
    code_attribute = {0.90, 0.49, 0.45, 1.0},       -- E67D74FF
    code_macro = {0.88, 0.68, 0.51, 1.0},           -- E0AD82FF
    code_directive = {0.90, 0.49, 0.45, 1.0},       -- E67D74FF
    
    ui_default = {0.75, 0.79, 0.86, 1.0},           -- BFC9DBFF
    ui_dim = {0.53, 0.57, 0.62, 1.0},               -- 87919DFF  
    ui_neutral = {0.30, 0.30, 0.30, 1.0},           -- 4C4C4CFF
    ui_error = {0.47, 0.13, 0.13, 1.0},             -- 772222FF
    ui_error_bright = {1.0, 0.0, 0.0, 1.0},         -- FF0000FF
    ui_warning = {0.97, 0.68, 0.20, 1.0},           -- F8AD34FF
    ui_warning_dim = {0.60, 0.38, 0.20, 1.0},       -- 986032FF
    ui_success = {0.13, 0.47, 0.13, 1.0}            -- 227722FF
}

local config_syntax_colors = {
    config_comment = {0.6, 0.6, 0.6, 1.0},           -- Light gray for comments
    config_section_header = {0.2, 0.8, 0.2, 1.0},    -- Green for section headers
    config_color_key = {0.8, 0.4, 0.8, 1.0},         -- Purple for color keys
    config_keybind_key = {0.4, 0.6, 1.0, 1.0},       -- Blue for keybind keys  
    config_setting_key = {0.8, 0.8, 0.4, 1.0},       -- Yellow for setting keys
    config_separator = {0.7, 0.7, 0.7, 1.0},         -- Light gray for colons
    config_hex_value = {1.0, 0.6, 0.4, 1.0},         -- Orange for hex values
    config_action_value = {0.4, 0.8, 0.6, 1.0},      -- Teal for action values
    config_string_value = {0.6, 0.8, 0.8, 1.0},      -- Light cyan for strings
    config_number_value = {1.0, 0.8, 0.4, 1.0},      -- Light orange for numbers
    config_default = {0.9, 0.9, 0.9, 1.0}            -- White for default
}

local function hex_to_color(hex_string)
    if not hex_string or #hex_string < 6 then
        return nil
    end
    
    hex_string = hex_string:gsub("#", "")
    
    if #hex_string == 6 then
        local r = tonumber(hex_string:sub(1, 2), 16) / 255
        local g = tonumber(hex_string:sub(3, 4), 16) / 255
        local b = tonumber(hex_string:sub(5, 6), 16) / 255
        return {r, g, b, 1.0}
    elseif #hex_string == 8 then
        local r = tonumber(hex_string:sub(1, 2), 16) / 255
        local g = tonumber(hex_string:sub(3, 4), 16) / 255
        local b = tonumber(hex_string:sub(5, 6), 16) / 255
        local a = tonumber(hex_string:sub(7, 8), 16) / 255
        return {r, g, b, a}
    end
    
    return nil
end

local function load_colors_from_config()
    local config = require("config")
    current_colors = {}
    
    for name, color in pairs(default_colors) do
        current_colors[name] = {color[1], color[2], color[3], color[4]}
    end
    
    local config_colors = config.get("colors") or {}
    for name, hex_value in pairs(config_colors) do
        local color = hex_to_color(hex_value)
        if color then
            current_colors[name] = color
        end
    end
end

function colors.load()
    load_colors_from_config()
    print("Colors loaded")
end

function colors.reload()
    local config = require("config")
    config.reload()
    
    load_colors_from_config()
    print("Colors reloaded")
end

function colors.get(color_name)
    if config_syntax_colors[color_name] then
        return config_syntax_colors[color_name]
    end
    
    return current_colors[color_name] or default_colors[color_name] or {1.0, 1.0, 1.0, 1.0}
end

function colors.set_color(color_name)
    local color = colors.get(color_name)
    love.graphics.setColor(color[1], color[2], color[3], color[4])
end

return colors