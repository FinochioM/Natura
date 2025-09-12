local syntax = {}
local langs = require("langs.init")

local buffer_tokens = {}

function syntax.tokenize_buffer(buffer)
    if not buffer.language then 
        buffer_tokens[buffer] = {}
        return
    end
    
    local full_text = table.concat(buffer.lines, "\n")
    local tokens = langs.tokenize_buffer(buffer.language, full_text)
    
    local line_tokens = {}
    for i = 1, #buffer.lines do
        line_tokens[i] = {}
    end
    
    local line_starts = {1} -- positions where each line starts
    for i = 1, #buffer.lines - 1 do
        line_starts[i + 1] = line_starts[i] + #buffer.lines[i] + 1 -- +1 for newline
    end
    
    for _, token in ipairs(tokens) do
        local line_num = 1
        for i = 2, #line_starts do
            if token.start >= line_starts[i] then
                line_num = i
            else
                break
            end
        end
        
        local line_relative_start = token.start - line_starts[line_num] + 1
        
        table.insert(line_tokens[line_num], {
            type = token.type,
            start = line_relative_start,
            length = token.length
        })
    end
    
    buffer_tokens[buffer] = line_tokens
end

function syntax.get_line_tokens(buffer, line_num)
    if not buffer_tokens[buffer] then
        syntax.tokenize_buffer(buffer)
    end
    return buffer_tokens[buffer][line_num] or {}
end

function syntax.invalidate_buffer(buffer)
    buffer_tokens[buffer] = nil
end

return syntax