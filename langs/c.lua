local c_lang = {}

local TOKEN_TYPES = {
    DEFAULT = "default",
    KEYWORD = "keyword",
    TYPE = "type",
    VALUE = "value",
    MODIFIER = "modifier",
    DIRECTIVE = "directive",
    IDENTIFIER = "identifier",
    FUNCTION = "function",
    STRING_LITERAL = "string_literal",
    CHAR_LITERAL = "char_literal",
    COMMENT = "comment",
    MULTILINE_COMMENT = "multiline_comment",
    NUMBER = "number",
    PUNCTUATION = "punctuation",
    OPERATION = "operation"
}

local C_KEYWORDS = {
    ["break"] = true, ["case"] = true, ["continue"] = true, ["default"] = true,
    ["do"] = true, ["else"] = true, ["enum"] = true, ["for"] = true,
    ["goto"] = true, ["if"] = true, ["return"] = true, ["sizeof"] = true,
    ["struct"] = true, ["switch"] = true, ["typedef"] = true, ["union"] = true,
    ["while"] = true, ["_Atomic"] = true, ["_Generic"] = true, ["_Noreturn"] = true,
    ["_Static_assert"] = true, ["__asm"] = true, ["__asm__"] = true,
    ["__except"] = true, ["__finally"] = true, ["__leave"] = true, ["__try"] = true
}

local C_TYPE_KEYWORDS = {
    ["char"] = true, ["double"] = true, ["float"] = true, ["int"] = true,
    ["long"] = true, ["short"] = true, ["void"] = true, ["_Bool"] = true,
    ["_Complex"] = true, ["_Imaginary"] = true, ["int8_t"] = true,
    ["int16_t"] = true, ["int32_t"] = true, ["int64_t"] = true,
    ["uint8_t"] = true, ["uint16_t"] = true, ["uint32_t"] = true,
    ["uint64_t"] = true, ["size_t"] = true, ["ptrdiff_t"] = true,
    ["intptr_t"] = true, ["uintptr_t"] = true
}

local C_VALUE_KEYWORDS = {
    ["true"] = true, ["false"] = true, ["NULL"] = true
}

local C_MODIFIER_KEYWORDS = {
    ["const"] = true, ["extern"] = true, ["register"] = true,
    ["signed"] = true, ["static"] = true, ["unsigned"] = true,
    ["volatile"] = true, ["_Thread_local"] = true
}

local C_DIRECTIVES = {
    ["define"] = true, ["elif"] = true, ["elifdef"] = true, ["elifndef"] = true,
    ["else"] = true, ["end"] = true, ["endif"] = true, ["error"] = true,
    ["if"] = true, ["ifdef"] = true, ["ifndef"] = true, ["include"] = true,
    ["line"] = true, ["pragma"] = true, ["undef"] = true, ["warning"] = true
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

function c_lang.tokenize(text)
    local tokens = {}
    local i = 1
    local len = #text
    
    while i <= len do
        local char = text:sub(i, i)
        
        if char:match("%s") then
            i = i + 1
        
        elseif char == "/" and i < len and text:sub(i+1, i+1) == "/" then
            local start = i
            i = i + 2
            while i <= len and text:sub(i, i) ~= "\n" do
                i = i + 1
            end
            table.insert(tokens, {
                type = TOKEN_TYPES.COMMENT,
                start = start,
                length = i - start
            })
        
        elseif char == "/" and i < len and text:sub(i+1, i+1) == "*" then
            local start = i
            i = i + 2
            while i < len do
                if text:sub(i, i+1) == "*/" then
                    i = i + 2
                    break
                end
                i = i + 1
            end
            table.insert(tokens, {
                type = TOKEN_TYPES.MULTILINE_COMMENT,
                start = start,
                length = i - start
            })
        
        elseif char == "#" then
            local start = i
            i = i + 1
            
            while i <= len and text:sub(i, i):match("%s") do
                i = i + 1
            end
            
            if i <= len and is_alpha(text:sub(i, i)) then
                local directive_start = i
                while i <= len and is_alnum(text:sub(i, i)) do
                    i = i + 1
                end
                local directive = text:sub(directive_start, i - 1)
                
                if C_DIRECTIVES[directive] then
                    table.insert(tokens, {
                        type = TOKEN_TYPES.DIRECTIVE,
                        start = start,
                        length = i - start
                    })
                    
                    if directive == "include" then
                        while i <= len and text:sub(i, i):match("%s") do
                            i = i + 1
                        end
                        if i <= len and text:sub(i, i) == "<" then
                            local include_start = i
                            while i <= len and text:sub(i, i) ~= ">" and text:sub(i, i) ~= "\n" do
                                i = i + 1
                            end
                            if i <= len and text:sub(i, i) == ">" then
                                i = i + 1
                            end
                            table.insert(tokens, {
                                type = TOKEN_TYPES.STRING_LITERAL,
                                start = include_start,
                                length = i - include_start
                            })
                        end
                    end
                else
                    table.insert(tokens, {
                        type = TOKEN_TYPES.DEFAULT,
                        start = start,
                        length = i - start
                    })
                end
            else
                i = start + 1
                table.insert(tokens, {
                    type = TOKEN_TYPES.DEFAULT,
                    start = start,
                    length = 1
                })
            end
        
        elseif char == '"' then
            local start = i
            i = i + 1
            local escape = false
            
            while i <= len do
                local c = text:sub(i, i)
                if c == '"' and not escape then
                    i = i + 1
                    break
                elseif c == "\n" then
                    break
                end
                escape = (c == "\\" and not escape)
                i = i + 1
            end
            
            table.insert(tokens, {
                type = TOKEN_TYPES.STRING_LITERAL,
                start = start,
                length = i - start
            })
        
        elseif char == "'" then
            local start = i
            i = i + 1
            local escape = false
            
            if i <= len and text:sub(i, i) == "\\" then
                escape = true
                i = i + 1
            end
            
            if i <= len and text:sub(i, i) ~= "\n" then
                i = i + 1
            end
            
            if i <= len and text:sub(i, i) == "'" then
                i = i + 1
            end
            
            table.insert(tokens, {
                type = TOKEN_TYPES.CHAR_LITERAL,
                start = start,
                length = i - start
            })
        
        elseif is_digit(char) or (char == "." and i < len and is_digit(text:sub(i+1, i+1))) then
            local start = i
            
            while i <= len and (is_alnum(text:sub(i, i)) or text:sub(i, i) == ".") do
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
            local token_type = TOKEN_TYPES.IDENTIFIER
            
            if C_KEYWORDS[word] then
                token_type = TOKEN_TYPES.KEYWORD
            elseif C_TYPE_KEYWORDS[word] then
                token_type = TOKEN_TYPES.TYPE
            elseif C_VALUE_KEYWORDS[word] then
                token_type = TOKEN_TYPES.VALUE
            elseif C_MODIFIER_KEYWORDS[word] then
                token_type = TOKEN_TYPES.MODIFIER
            end
            
            table.insert(tokens, {
                type = token_type,
                start = start,
                length = i - start
            })
        
        elseif char:match("[+%-%*/%%=<>!&|^~?:]") then
            local start = i
            i = i + 1
            
            if i <= len then
                local two_char = text:sub(start, i)
                if two_char == "++" or two_char == "--" or two_char == "==" or 
                   two_char == "!=" or two_char == "<=" or two_char == ">=" or
                   two_char == "&&" or two_char == "||" or two_char == "<<" or
                   two_char == ">>" or two_char == "+=" or two_char == "-=" or
                   two_char == "*=" or two_char == "/=" or two_char == "%=" or
                   two_char == "&=" or two_char == "|=" or two_char == "^=" or
                   two_char == "->" then
                    i = i + 1
                end
            end
            
            table.insert(tokens, {
                type = TOKEN_TYPES.OPERATION,
                start = start,
                length = i - start
            })
        
        elseif char:match("[;,%.(){}%[%]\\]") then
            table.insert(tokens, {
                type = TOKEN_TYPES.PUNCTUATION,
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
    
    for idx = 1, #tokens - 1 do
        if tokens[idx].type == TOKEN_TYPES.IDENTIFIER and 
           tokens[idx + 1].type == TOKEN_TYPES.PUNCTUATION then
            local punc_text = text:sub(tokens[idx + 1].start, tokens[idx + 1].start)
            if punc_text == "(" then
                tokens[idx].type = TOKEN_TYPES.FUNCTION
            end
        end
    end
    
    return tokens
end

return c_lang