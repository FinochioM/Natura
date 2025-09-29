local welcome = {}
local colors = require("colors")
local version = require("version")

local WELCOME_CONTENT = {
    title = "Natura Editor",
    version = "v0.1.0",
    subtitle = "A simple, fast editor built with Lua",
    commands = {
        {"Alt+X", " Open Actions Menu"},
        {"Ctrl+O", "Open File"},
        {"Ctrl+G", "Go to Line"},
        {"Ctrl+S", "Save"},
        {"Ctrl+Z", "Undo"},
        {"Ctrl+Y", "Redo"},
        {"Escape", "Clear Selection"}
    }
}

function welcome.is_showing()
    local has_filepath = current_buffer and current_buffer.filepath and current_buffer.filepath ~= ""
    local is_new_file = current_buffer and current_buffer.is_new
    return not (has_filepath or is_new_file)
end

function welcome.draw()
    if not welcome.is_showing() then return end
    
    local font = love.graphics.getFont()
    local window_width = love.graphics.getWidth()
    local window_height = love.graphics.getHeight()
    
    local center_x = window_width / 2
    local start_y = 100
    
    colors.set_color("text")
    local title_font_size = 32
    local title_font = love.graphics.newFont(title_font_size)
    love.graphics.setFont(title_font)
    local title_width = title_font:getWidth(WELCOME_CONTENT.title)
    love.graphics.print(WELCOME_CONTENT.title, center_x - title_width / 2, start_y)
    
    love.graphics.setFont(font)
    colors.set_color("text_dim")
    
    local current_version = version.get_version()
    local version_width = font:getWidth(current_version)
    love.graphics.print(current_version, center_x - version_width / 2, start_y + 45)
    
    local current_date = version.get_date()
    local date_width = font:getWidth(current_date)
    love.graphics.print(current_date, center_x - date_width / 2, start_y + 65)
    
    local subtitle_width = font:getWidth(WELCOME_CONTENT.subtitle)
    love.graphics.print(WELCOME_CONTENT.subtitle, center_x - subtitle_width / 2, start_y + 90)
    
    colors.set_color("text")
    local commands_title = "Essential Commands:"
    local commands_width = font:getWidth(commands_title)
    love.graphics.print(commands_title, center_x - commands_width / 2, start_y + 140)
    
    local cmd_start_y = start_y + 170
    for i, cmd in ipairs(WELCOME_CONTENT.commands) do
        local y = cmd_start_y + (i - 1) * 25
        local key_combo = cmd[1]
        local description = cmd[2]
        
        colors.set_color("ui_success")
        local key_width = font:getWidth(key_combo)
        love.graphics.print(key_combo, center_x - 100, y)
        
        colors.set_color("text_dim")
        love.graphics.print(description, center_x - 100 + key_width + 20, y)
    end
    
    colors.set_color("text_dim")
    local footer_text = "Open a file to start editing"
    local footer_width = font:getWidth(footer_text)
    love.graphics.print(footer_text, center_x - footer_width / 2, window_height - 50)
end

return welcome