local lua_lang = {}

local TOKEN_TYPES = {
    DEFAULT = "default",
    KEYWORD = "keyword", 
    IDENTIFIER = "identifier",
    FUNCTION = "function",
    STRING_LITERAL = "string_literal",
    COMMENT = "comment",
    NUMBER = "number",
    PUNCTUATION = "punctuation"
}

local LUA_KEYWORDS = {
    ["and"] = true, ["break"] = true, ["do"] = true, ["else"] = true,
    ["elseif"] = true, ["end"] = true, ["false"] = true, ["for"] = true,
    ["function"] = true, ["goto"] = true, ["if"] = true, ["in"] = true,
    ["local"] = true, ["nil"] = true, ["not"] = true, ["or"] = true,
    ["repeat"] = true, ["return"] = true, ["then"] = true, ["true"] = true,
    ["until"] = true, ["while"] = true
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

function lua_lang.tokenize(text)
    local tokens = {}
    local i = 1
    local len = #text
    
    while i <= len do
        local char = text:sub(i, i)
        
        if char:match("%s") then
            i = i + 1
        
        elseif char == "-" and i < len and text:sub(i+1, i+1) == "-" then
            local start = i
            i = i + 2
            
            if i <= len-2 and text:sub(i, i+1) == "[[" then
                i = i + 2
                while i <= len-1 do
                    if text:sub(i, i+1) == "]]" then
                        i = i + 2
                        break
                    end
                    i = i + 1
                end
            else
                while i <= len and text:sub(i, i) ~= "\n" do
                    i = i + 1
                end
            end
            
            table.insert(tokens, {
                type = TOKEN_TYPES.COMMENT,
                start = start,
                length = i - start
            })
        
        elseif char == '"' or char == "'" then
            local quote = char
            local start = i
            i = i + 1
            
            while i <= len do
                local c = text:sub(i, i)
                if c == quote then
                    i = i + 1
                    break
                elseif c == "\\" and i < len then
                    i = i + 2
                else
                    i = i + 1
                end
            end
            
            table.insert(tokens, {
                type = TOKEN_TYPES.STRING_LITERAL,
                start = start,
                length = i - start
            })
        
        elseif is_digit(char) then
            local start = i
            
            while i <= len and (is_digit(text:sub(i, i)) or text:sub(i, i) == ".") do
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
            
            local word = text:sub(start, i - 1)
            local token_type = LUA_KEYWORDS[word] and TOKEN_TYPES.KEYWORD or TOKEN_TYPES.IDENTIFIER
            
            table.insert(tokens, {
                type = token_type,
                start = start,
                length = i - start
            })
        
        else
            table.insert(tokens, {
                type = TOKEN_TYPES.PUNCTUATION,
                start = i,
                length = 1
            })
            i = i + 1
        end
    end
    
    return tokens
end

return lua_lang