local search = {}
local editor = require("editor")

function search.create()
    return {
        active = false,
        query = "",
        results = {},
        current_result = 0,
        case_sensitive = false,
        whole_word = false
    }
end

function search.set_query(s, query)
    s.query = query
    search.find_all(s)
end

function search.find_all(s, buf)
    s.results = {}
    if s.query == "" or not buf then
        return
    end
    
    local query = s.case_sensitive and s.query or s.query:lower()
    
    for line_num, line in ipairs(buf.lines) do
        local search_line = s.case_sensitive and line or line:lower()
        local start_pos = 1
        
        while true do
            local found_start, found_end
            
            if s.whole_word then
                local pattern = "%f[%w]" .. query:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1") .. "%f[%W]"
                found_start, found_end = search_line:find(pattern, start_pos)
            else
                found_start, found_end = search_line:find(query, start_pos, true)
            end
            
            if not found_start then break end
            
            table.insert(s.results, {
                line = line_num,
                start_col = found_start - 1,  -- Convert to 0-based
                end_col = found_end,
                text = line:sub(found_start, found_end)
            })
            
            start_pos = found_start + 1
        end
    end
    
    s.current_result = #s.results > 0 and 1 or 0
end

function search.goto_next(s, ed, buf)
    if #s.results == 0 then return end
    
    s.current_result = s.current_result + 1
    if s.current_result > #s.results then
        s.current_result = 1
    end
    
    search.goto_current_result(s, ed, buf)
end

function search.goto_previous(s, ed, buf)
    if #s.results == 0 then return end
    
    s.current_result = s.current_result - 1
    if s.current_result < 1 then
        s.current_result = #s.results
    end
    
    search.goto_current_result(s, ed, buf)
end

function search.goto_current_result(s, ed, buf)
    if #s.results == 0 or s.current_result == 0 then return end
    
    local result = s.results[s.current_result]
    ed.cursor_line = result.line
    ed.cursor_col = result.start_col
    
    ed.selection.active = true
    ed.selection.start_line = result.line
    ed.selection.start_col = result.start_col
    ed.selection.end_line = result.line
    ed.selection.end_col = result.end_col
    
    editor.update_viewport(ed, buf)
end

function search.toggle_case_sensitive(s, buf)
    s.case_sensitive = not s.case_sensitive
    search.find_all(s, buf)
end

function search.toggle_whole_word(s, buf)
    s.whole_word = not s.whole_word
    search.find_all(s, buf)
end

function search.close(s)
    s.active = false
    s.query = ""
    s.results = {}
    s.current_result = 0
end

return search