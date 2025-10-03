local project = {}

local current_project = {
    loaded = false,
    filepath = nil,
    version = 0,
    workspace_dirs = {},
    ignore_patterns = {},
    file_associations = {},
    build_working_dir = nil,
    open_panel_on_build = true,
    clear_build_output_before_running = true,
    error_regex = nil,
    auto_jump_to_error = true,
    build_commands = {}
}

local function trim(s)
    return s:match("^%s*(.-)%s*$")
end

local function parse_project_file(filepath)
    local file = io.open(filepath, "r")
    if not file then
        return nil, "Could not open file: " .. filepath
    end
    
    local content = file:read("*all")
    file:close()
    
    local project_data = {
        version = 0,
        workspace_dirs = {},
        ignore_patterns = {},
        file_associations = {},
        build_working_dir = nil,
        build_commands = {}
    }
    
    local current_section = nil
    local current_build_command = nil
    
    for line in content:gmatch("[^\r\n]+") do
        line = trim(line)
        
        if line == "" or line:match("^#") then
            goto continue
        end
        
        if line:match("^%[(%d+)%]") then
            project_data.version = tonumber(line:match("^%[(%d+)%]"))
            goto continue
        end
        
        if line:match("^%[%[workspace%]%]") then
            current_section = "workspace"
            current_build_command = nil
            goto continue
        end
        
        if line:match("^%[ignore%]") then
            current_section = "ignore"
            current_build_command = nil
            goto continue
        end
        
        if line:match("^%[file associations%]") then
            current_section = "file_associations"
            current_build_command = nil
            goto continue
        end
        
        if line:match("^%[%[build commands%]%]") then
            current_section = "build_defaults"
            current_build_command = nil
            goto continue
        end
        
        if line:match("^%[.+%]$") and not line:match("^%[%[") then
            local cmd_name = line:match("^%[(.+)%]$")
            current_section = "build_command"
            current_build_command = {
                name = cmd_name,
                build_command = nil,
                run_command = nil,
                build_working_dir = nil,
                run_working_dir = nil,
                key_binding = nil,
                timeout_in_seconds = nil
            }
            table.insert(project_data.build_commands, current_build_command)
            goto continue
        end

        if current_section == "ignore" then
            table.insert(project_data.ignore_patterns, line)
            goto continue
        end
        
        local key, value = line:match("^([^:]+):%s*(.*)$")
        if key and value then
            key = trim(key)
            value = trim(value)
            
            if current_section == "workspace" then
                if value ~= "" then
                    table.insert(project_data.workspace_dirs, value)
                end
            elseif current_section == "ignore" then
                if value ~= "" then
                    table.insert(project_data.ignore_patterns, value)
                end
            elseif current_section == "file_associations" then
                local pattern, lang = value:match("^(.+)%s*:%s*(.+)$")
                if pattern and lang then
                    table.insert(project_data.file_associations, {pattern = trim(pattern), lang = trim(lang)})
                end
            elseif current_section == "build_defaults" then
                if key == "build_working_dir" then
                    project_data.build_working_dir = value
                elseif key == "open_panel_on_build" then
                    project_data.open_panel_on_build = (value == "true")
                elseif key == "clear_build_output_before_running" then
                    project_data.clear_build_output_before_running = (value == "true")
                elseif key == "error_regex" then
                    project_data.error_regex = value
                elseif key == "auto_jump_to_error" then
                    project_data.auto_jump_to_error = (value == "true")
                end
            elseif current_section == "build_command" and current_build_command then
                if key == "build_command" then
                    current_build_command.build_command = value
                elseif key == "run_command" then
                    current_build_command.run_command = value
                elseif key == "build_working_dir" then
                    current_build_command.build_working_dir = value
                elseif key == "run_working_dir" then
                    current_build_command.run_working_dir = value
                elseif key == "key_binding" then
                    current_build_command.key_binding = value
                elseif key == "timeout_in_seconds" then
                    current_build_command.timeout_in_seconds = tonumber(value)
                end
            end
        end
        
        ::continue::
    end
    
    return project_data, nil
end

function project.load(filepath)
    local data, err = parse_project_file(filepath)
    if not data then
        print("ERROR: Failed to load project: " .. (err or "unknown error"))
        return false
    end
    
    current_project.loaded = true
    current_project.filepath = filepath
    current_project.version = data.version
    current_project.workspace_dirs = data.workspace_dirs
    current_project.ignore_patterns = data.ignore_patterns
    current_project.file_associations = data.file_associations
    current_project.build_working_dir = data.build_working_dir
    current_project.build_commands = data.build_commands
    
    print("Loaded project: " .. filepath)
    print("Workspace directories: " .. #current_project.workspace_dirs)
    
    return true
end

function project.get_current()
    return current_project
end

function project.is_loaded()
    return current_project.loaded
end

function project.should_ignore(path, name)
    if not current_project.loaded then
        return false
    end
    
    for _, pattern in ipairs(current_project.ignore_patterns) do
        if pattern:match("%*%*") then
            local regex_pattern = "^" .. pattern:gsub("%*%*", ".*"):gsub("%*", "[^/\\]*"):gsub("%.", "%%."):gsub("%?", ".") .. "$"
            if path:match(regex_pattern) then
                return true
            end
        elseif pattern:match("%*") then
            local regex_pattern = "^" .. pattern:gsub("%*", "[^/\\]*"):gsub("%.", "%%."):gsub("%?", ".") .. "$"
            if name:match(regex_pattern) then
                return true
            end
        else
            if name == pattern or path:match(pattern) then
                return true
            end
        end
    end
    
    return false
end

function project.get_language_for_file(filename)
    if not current_project.loaded then
        return nil
    end
    
    for _, assoc in ipairs(current_project.file_associations) do
        local pattern = assoc.pattern
        
        if pattern:match("%*") then
            local lua_pattern = "^" .. pattern:gsub("%.", "%%."):gsub("%*", ".*") .. "$"
            if filename:match(lua_pattern) then
                return assoc.lang
            end
        else
            if filename == pattern then
                return assoc.lang
            end
        end
    end
    
    return nil
end

function project.close()
    current_project.loaded = false
    current_project.filepath = nil
    current_project.workspace_dirs = {}
    current_project.ignore_patterns = {}
    current_project.file_associations = {}
    current_project.build_commands = {}
    print("Project closed")
end

return project