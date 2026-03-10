local profile = {}

--[[
	See ../tools/profile.luau
]]

local BufferSerializer = require("@BufferSerializer")

local function ds(a: any)
	return BufferSerializer.deserialize(BufferSerializer.serialize(a))
end

-- Different data structures to test
local numberArray = {}
for i = 1, 30 do
	numberArray[i] = i
end

local duplicateArray = {}
for i = 1, 30 do
	duplicateArray[i] = "Hello World!"
end

local mixedData
mixedData = {
	number = 123.456,
	string = "Hello, world!",
	boolean = true,
	buffer = buffer.create(10),
	vector = vector.create(1, 2),
	table = { 1, 2, 3, function() end, key = "value" },
	nested = {
		{ a = 1, b = 2 },
		{ c = 3, d = 4 },
	},
	recursive = mixedData,
	userdata = newproxy(),
}

-- Modify this data to test different scenarios
local function runNumberArray()
	ds(numberArray)
end
local function runDuplicateArray()
	ds(duplicateArray)
end
local function runMixedData()
	ds(mixedData)
end

function Profile(runTimes: number)
	for i = 1, runTimes do
		runNumberArray()
		runMixedData()
		runDuplicateArray()
	end
end
Profile(1000)

return profile
