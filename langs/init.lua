local langs = {}

local available_languages = {
    lua = require("langs.lua"),
    config = require("langs.config"),
    batch = require("langs.batch"),
}

function langs.get_language_from_extension(extension)
    local lang_map = {
        [".lua"] = "lua",
        [".config"] = "config",
        [".bat"] = "batch",
        [".cmd"] = "batch",
    }
    return lang_map[extension]
end

function langs.tokenize_buffer(lang_name, text)
    local language = available_languages[lang_name]
    if language then
        return language.tokenize(text)
    end
    return {}
end

function langs.get_supported_languages()
    local supported = {}
    for lang_name, _ in pairs(available_languages) do
        table.insert(supported, lang_name)
    end
    return supported
end

return langs