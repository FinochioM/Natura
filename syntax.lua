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
    
    local line_starts = {1} -- Line 1 starts at position 1
    local current_pos = 1
    for i = 1, #buffer.lines - 1 do
        current_pos = current_pos + #buffer.lines[i] + 1 -- +1 for newline
        line_starts[i + 1] = current_pos
    end
    
    local function get_line_for_position(pos)
        for i = #line_starts, 1, -1 do
            if pos >= line_starts[i] then
                return i
            end
        end
        return 1
    end
    
    for _, token in ipairs(tokens) do
        local token_start = token.start
        local token_end = token.start + token.length - 1
        
        local start_line = get_line_for_position(token_start)
        local end_line = get_line_for_position(token_end)
        
        for line_num = start_line, end_line do
            local line_start_pos = line_starts[line_num]
            local line_end_pos
            if line_num == #buffer.lines then
                line_end_pos = #full_text
            else
                line_end_pos = line_starts[line_num + 1] - 2 -- -1 for newline, -1 for 0-based
            end
            
            local token_start_on_line = math.max(1, token_start - line_start_pos + 1)
            local token_end_on_line = math.min(#buffer.lines[line_num], token_end - line_start_pos + 1)
            
            if token_start_on_line <= token_end_on_line and token_end_on_line >= 1 then
                table.insert(line_tokens[line_num], {
                    type = token.type,
                    start = token_start_on_line,
                    length = token_end_on_line - token_start_on_line + 1
                })
            end
        end
    end
    
    for i = 1, #line_tokens do
        table.sort(line_tokens[i], function(a, b) return a.start < b.start end)
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

function syntax.debug_tokens(buffer, line_num)
    local tokens = syntax.get_line_tokens(buffer, line_num)
    local line = buffer.lines[line_num]
    print("Line " .. line_num .. ": '" .. line .. "'")
    for i, token in ipairs(tokens) do
        local text = line:sub(token.start, token.start + token.length - 1)
        print("  Token " .. i .. ": type=" .. token.type .. ", start=" .. token.start .. ", length=" .. token.length .. ", text='" .. text .. "'")
    end
end

return syntax