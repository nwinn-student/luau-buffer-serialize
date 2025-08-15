--[[
	COMPARISON BENCHMARK - FOR - BUFFERSERIALIZER
		
	Notes:
	    Bench can be found at https://github.com/nwinn-student/luau-bench
	    msgpack can be found at https://github.com/cipharius/msgpack-luau
	    Roblox JSON will be faster than most other luau JSON implementations

	Datasets (only table / number / string are used):
		bench - created by https://github.com/nwinn-student/luau-bench
		
		Found at: https://github.com/jdorfman/awesome-json-datasets
		food-facts - https://world.openfoodfacts.org/api/v0/product/5060292302201.json
		pokedex - https://raw.githubusercontent.com/Biuni/PokemonGO-Pokedex/master/pokedex.json
		prize - https://api.nobelprize.org/v1/prize.json
]]--

local bench = require("./Bench/Bench")
local benchPrecision = require("./Bench/internal/Print").precision

local benchMethods = getmetatable(bench(function() end)).__index

-- Makes the output look much neater
function benchMethods:summarize(name: string)
	self.Name = name
	
	local str = `Name: {name}\n    Speed: [seconds]\n        Median: {
		benchPrecision(self.Speed.Median, 4)
	}\n    Memory: [kB]\n        Avg:    {
		benchPrecision(self.Memory.Average, 4)
	}`
	
	local typeOutput = type(self.Output)
	if typeOutput == "string" or typeOutput == "buffer" then
		str ..= `\n    Size:   {
			if typeOutput == "string" then #self.Output
			else buffer.len(self.Output)
		} bytes`
	end
	print(str)
	return self
end


local bufferSerial = require("./BufferSerializer/BufferSerializer")
local serialize = bufferSerial.serialize
local deserialize = bufferSerial.deserialize

-- For Roblox this could be a wrapper to HTTPService's JSONEncode
-- For Non-Roblox this could just be another JSON library
local json = require("./json")

-- We assume typical calls are json:Encode(data)
local jsonEncode = json.Encode
local jsonDecode = json.Decode

local msgpack = require("./msgpack")
local msgpackEncode = msgpack.encode
local msgpackDecode = msgpack.decode

function test(testData: {[any]: any}, name: string)
	bench(serialize, testData)
		:withName(`Serial {name}`)
		:updateOutput(function(output)
			return `Size: {buffer.len(output)}`
		end)
		-- Add task.wait() if supported
		:print()
		:compare(
			bench(jsonEncode, json, testData)
				-- Add task.wait() if supported
				:summarize(`JSON {name}`),
			bench(msgpackEncode, testData)
				-- Add task.wait() if supported
				:summarize(`MsgpackEncode {name}`)
		):print()

	bench(deserialize, serialize(testData))
		:withName(`Deserial {name}`)
		:updateOutput()
		-- Add task.wait() if supported
		:print()
		:compare(
			bench(jsonDecode, json, jsonEncode(json, testData))
				-- Add task.wait() if supported
				:withName(`JSONDecode {name}`),
			bench(msgpackDecode, msgpackEncode(testData))
				-- Add task.wait() if supported
				:withName(`MsgpackDecode {name}`)
		):print()
end

test(bench(function() end), "Bench")
test(jsonDecode(json, require("./food-facts")), "Food Facts")
test(jsonDecode(json, require("./pokedex")), "Pokedex")
test(jsonDecode(json, require("./prize")), "Prize")