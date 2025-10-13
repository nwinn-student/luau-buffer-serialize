--[[
	Note: This benchmark is designed to be run with Luau's built-in profiler.

	Use `luau --profile bench/profile.luau` to create a profile.out file.
	Use `python path/to/luau/tools/perfgraph.py profile.out > profile.svg` to generate a flamegraph.
	Open profile.svg in a web browser to view the flamegraph.

	It is recommended to place the tools folder from the Luau repository inside this repository.
	It is also recommended to use the following bash command to run the profiler and generate the flamegraph in one go:

	For Windows (PowerShell):
	```bash
	luau --profile bench/profile.luau ; python tools/perfgraph.py profile.out > profile.svg ; .\profile.svg
	```
	For Linux:
	```bash
	luau --profile bench/profile.luau && python tools/perfgraph.py profile.out > profile.svg && xdg-open profile.svg
	```
]]
local profile = {}

local BufferSerializer = require("../src")

local function ds(a: any)
	return BufferSerializer.deserialize(BufferSerializer.serialize(a))
end

-- Different data structures to test
local numberArray = {}
for i = 1, 30 do
	numberArray[i] = i
end

local mixedData = {
	number = 123.456,
	string = "Hello, world!",
	boolean = true,
	table = { 1, 2, 3, key = "value" },
	nested = {
		{ a = 1, b = 2 },
		{ c = 3, d = 4 },
	},
}

-- Modify this data to test different scenarios
local function runNumberArray()
	for i = 1, 1000 do
		ds(numberArray)
	end
end
local function runMixedData()
	for i = 1, 1000 do
		ds(mixedData)
	end
end

runNumberArray()
runMixedData()

return profile
