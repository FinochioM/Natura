local version = {}

local current_version = {
    version = "v0.1.0",
    date = "26/09/2025",
    data = ""
}

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

function version.load()
    local version_path = "extras/VERSION"
    
    if not file_exists(version_path) then
        print("VERSION file not found, using default version")
        return
    end
    
    local content = read_file(version_path)
    if not content then
        print("Could not read VERSION file")
        return
    end
    
    local current_section = nil
    
    for line in content:gmatch("[^\r\n]+") do
        line = line:match("^%s*(.-)%s*$")
        
        if line:match("^%[%[(.+)%]%]$") then
            current_section = line:match("^%[%[(.+)%]%]$")
        elseif line ~= "" and not line:match("^#") then
            if current_section == "version" then
                current_version.version = "v" .. line
            elseif current_section == "date" then
                current_version.date = line
            elseif current_section == "data" then
                if current_version.data == "" then
                    current_version.data = line
                else
                    current_version.data = current_version.data .. "\n" .. line
                end
            end
        end
    end
    
    print("Loaded version: " .. current_version.version .. " (" .. current_version.date .. ")")
end

function version.get_version()
    return current_version.version
end

function version.get_date()
    return current_version.date
end

function version.get_data()
    return current_version.data
end

function version.get_full_info()
    return current_version
end

return version