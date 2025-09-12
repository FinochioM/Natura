-- Comment
--[[
    Multiline Comment
--]]

local PI = 3.14159

local function calculateArea(radius)
    if radius <= 0 then
        error("Radius must be greater than zero")
    end
    return PI * radius * radius
end

local numbers = {1, 2, 3, 4, 5}

for i = 1, #numbers do
    print("Number:", numbers[i])
end

local person = {
    firstName = "John",
    lastName = "Doe",
    age = 30,
    getFullName = function(self)
        return self.firstName .. " " .. self.lastName
    end
}

print("Full Name:", person:getFullName())

local isTrue = true
local message = isTrue and "Hello, Lua!" or "Goodbye!"
print(message)

local status, result = pcall(calculateArea, 10)
if status then
    print("Area:", result)
else
    print("Error:", result)
end

local function fetchData(url)
    -- Simulate fetching data from a URL
    print("Fetching data from:", url)
    return {
        success = true,
        data = {
            id = 1,
            name = "Sample Data"
        }
    }
end

local data = fetchData("https://api.example.com/data")
if data.success then
    print("Data fetched:", data.data.name)
end


