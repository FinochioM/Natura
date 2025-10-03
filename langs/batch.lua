local batch_lang = {}

local TOKEN_TYPES = {
    DEFAULT = "default",
    KEYWORD = "keyword",
    COMMAND = "keyword",
    STRING = "string_literal",
    COMMENT = "comment",
    VARIABLE = "variable",
    BUILTIN_VARIABLE = "builtin_variable",
    LABEL = "label",
    OPERATION = "operation",
    PUNCTUATION = "punctuation",
    FLAG = "flag",
    NUMBER = "number"
}

local BATCH_COMMANDS = {
    ["cd"] = true, ["if"] = true, ["md"] = true, ["rd"] = true,
    ["cls"] = true, ["del"] = true, ["dir"] = true, ["for"] = true,
    ["rem"] = true, ["ren"] = true, ["set"] = true, ["ver"] = true,
    ["vol"] = true, ["call"] = true, ["copy"] = true, ["date"] = true,
    ["echo"] = true, ["exit"] = true, ["goto"] = true, ["keys"] = true,
    ["move"] = true, ["path"] = true, ["popd"] = true, ["time"] = true,
    ["type"] = true, ["assoc"] = true, ["break"] = true, ["chdir"] = true,
    ["color"] = true, ["dpath"] = true, ["erase"] = true, ["ftype"] = true,
    ["mkdir"] = true, ["pause"] = true, ["pushd"] = true, ["rmdir"] = true,
    ["shift"] = true, ["start"] = true, ["title"] = true, ["mklink"] = true,
    ["prompt"] = true, ["rename"] = true, ["verify"] = true, ["endlocal"] = true,
    ["setlocal"] = true
}

local BATCH_KEYWORDS = {
    ["not"] = true, ["exist"] = true, ["defined"] = true, ["in"] = true,
    ["else"] = true, ["do"] = true, ["equ"] = true, ["neq"] = true,
    ["lss"] = true, ["leq"] = true, ["gtr"] = true, ["geq"] = true,
    ["errorlevel"] = true, ["cmdextversion"] = true, ["nul"] = true
}

local function is_alpha(char)
    return char and char:match("[%a_]")
end

local function is_digit(char)
    return char and char:match("%d")
end

local function is_alnum(char)
    return char and char:match("[%w_]")
end

function batch_lang.tokenize(text)
    local tokens = {}
    local i = 1
    local len = #text
    
    while i <= len do
        local char = text:sub(i, i)
        
        if char:match("%s") then
            i = i + 1
        
        elseif i == 1 or text:sub(i-1, i-1):match("[\n\r]") then
            if text:sub(i, i+2):lower() == "rem" and (i+3 > len or text:sub(i+3, i+3):match("%s")) then
                local start = i
                while i <= len and not text:sub(i, i):match("[\n\r]") do
                    i = i + 1
                end
                table.insert(tokens, {
                    type = TOKEN_TYPES.COMMENT,
                    start = start,
                    length = i - start
                })
            
            elseif text:sub(i, i+1) == "::" then
                local start = i
                while i <= len and not text:sub(i, i):match("[\n\r]") do
                    i = i + 1
                end
                table.insert(tokens, {
                    type = TOKEN_TYPES.COMMENT,
                    start = start,
                    length = i - start
                })
            
            elseif text:sub(i, i) == ":" and is_alpha(text:sub(i+1, i+1)) then
                local start = i
                i = i + 1
                while i <= len and is_alnum(text:sub(i, i)) do
                    i = i + 1
                end
                table.insert(tokens, {
                    type = TOKEN_TYPES.LABEL,
                    start = start,
                    length = i - start
                })
            else
                i = i + 1
            end
        
        elseif char == '"' then
            local start = i
            i = i + 1
            while i <= len do
                local c = text:sub(i, i)
                if c == '"' then
                    i = i + 1
                    break
                elseif c:match("[\n\r]") then
                    break
                else
                    i = i + 1
                end
            end
            table.insert(tokens, {
                type = TOKEN_TYPES.STRING,
                start = start,
                length = i - start
            })
        
        elseif char == "%" or char == "!" then
            local start = i
            local delimiter = char
            i = i + 1
            
            if delimiter == "%" and i <= len then
                local next_char = text:sub(i, i)
                if next_char == "*" or is_digit(next_char) then
                    i = i + 1
                    table.insert(tokens, {
                        type = TOKEN_TYPES.VARIABLE,
                        start = start,
                        length = i - start
                    })
                    goto continue
                end
            end
            
            while i <= len and is_alnum(text:sub(i, i)) do
                i = i + 1
            end
            
            if i <= len and text:sub(i, i) == delimiter then
                i = i + 1
            end
            
            table.insert(tokens, {
                type = TOKEN_TYPES.VARIABLE,
                start = start,
                length = i - start
            })
            ::continue::
        
        elseif char:match("[<>|&^]") then
            local start = i
            i = i + 1
            if i <= len and (text:sub(i, i):match("[<>&|]") or text:sub(i, i) == char) then
                i = i + 1
            end
            table.insert(tokens, {
                type = TOKEN_TYPES.OPERATION,
                start = start,
                length = i - start
            })
        
        elseif (char == "/" or char == "-") and i > 1 and text:sub(i-1, i-1):match("%s") then
            local start = i
            i = i + 1
            while i <= len and not text:sub(i, i):match("[%s=:]") do
                i = i + 1
            end
            table.insert(tokens, {
                type = TOKEN_TYPES.FLAG,
                start = start,
                length = i - start
            })
        
        elseif char:match("[()%[%]]") then
            table.insert(tokens, {
                type = TOKEN_TYPES.PUNCTUATION,
                start = i,
                length = 1
            })
            i = i + 1
        
        elseif is_digit(char) then
            local start = i
            while i <= len and is_digit(text:sub(i, i)) do
                i = i + 1
            end
            table.insert(tokens, {
                type = TOKEN_TYPES.NUMBER,
                start = start,
                length = i - start
            })
        
        elseif is_alpha(char) then
            local start = i
            while i <= len and is_alnum(text:sub(i, i)) do
                i = i + 1
            end
            
            local word = text:sub(start, i - 1):lower()
            
            if BATCH_COMMANDS[word] then
                table.insert(tokens, {
                    type = TOKEN_TYPES.COMMAND,
                    start = start,
                    length = i - start
                })
            elseif BATCH_KEYWORDS[word] then
                table.insert(tokens, {
                    type = TOKEN_TYPES.KEYWORD,
                    start = start,
                    length = i - start
                })
            else
                table.insert(tokens, {
                    type = TOKEN_TYPES.DEFAULT,
                    start = start,
                    length = i - start
                })
            end
        
        elseif char:match("[=@]") then
            table.insert(tokens, {
                type = TOKEN_TYPES.OPERATION,
                start = i,
                length = 1
            })
            i = i + 1
        
        else
            table.insert(tokens, {
                type = TOKEN_TYPES.DEFAULT,
                start = i,
                length = 1
            })
            i = i + 1
        end
    end
    
    return tokens
end

return batch_lang