local parser = {}

function parser.parse_project_file(filepath)
    local config = {
        version = nil,
        workspace = {},
        ignore = {},
        file_associations = {},
        build_commands = {}
    }
    
    local content = love.filesystem.read(filepath)
    if not content then
        return nil
    end
    
    local current_section = nil
    local current_subsection = nil
    
    for line in content:gmatch("[^\r\n]+") do
        line = line:match("^%s*(.-)%s*$") -- trim whitespace
        
        if line == "" or line:match("^#") then
        elseif line:match("^%[(%d+)%]") then
            -- Version number
            config.version = tonumber(line:match("^%[(%d+)%]"))
        elseif line:match("^%[%[(.+)%]%]") then
            current_section = line:match("^%[%[(.+)%]%]"):lower()
            current_subsection = nil
        elseif line:match("^%[(.+)%]") then
            current_subsection = line:match("^%[(.+)%]")
            if current_section == "build commands" then
                config.build_commands[current_subsection] = {}
            end
        else
            if current_section == "workspace" then
                if line ~= "" then
                    table.insert(config.workspace, line)
                end
            elseif current_section == "ignore" then
                if line ~= "" then
                    table.insert(config.ignore, line)
                end
            elseif current_section == "file associations" then
                local key, value = line:match("^(.+)%s*:%s*(.+)$")
                if key and value then
                    config.file_associations[key:match("^%s*(.-)%s*$")] = value:match("^%s*(.-)%s*$")
                end
            end
        end
    end
    
    return config
end

return parser