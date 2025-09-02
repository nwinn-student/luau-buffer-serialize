--[[
	COMPARISON BENCHMARK - FOR - BUFFERSERIALIZER
	
	Used for comparing BufferSerializer's performance to other 
	general purpose serializers.
		
	Notes:
	    Bench can be found at https://github.com/nwinn-student/luau-bench
	    msgpack can be found at https://github.com/cipharius/msgpack-luau
	    json can be found at https://github.com/rxi/json.lua
		You do have to comment out line 78 though since it applies to a different JSON format

	Datasets (only table / number / string are used):
		Found at: https://github.com/jdorfman/awesome-json-datasets
		food-facts - https://world.openfoodfacts.org/api/v0/product/5060292302201.json
		pokedex - https://raw.githubusercontent.com/Biuni/PokemonGO-Pokedex/master/pokedex.json
		prize - https://api.nobelprize.org/v1/prize.json
]]--

local bench = require("./Bench")
local benchPrecision = require("./Bench/Print").precision

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
	-- Add task.wait() if supported
	return self
end


local bufferSerial = require("./BufferSerializer")
local serialize = bufferSerial.serialize
local deserialize = bufferSerial.deserialize

local json = require("./json")
local jsonEncode = json.encode
local jsonDecode = json.decode

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
			bench(jsonEncode, testData)
				:summarize(`JSON {name}`),
			bench(msgpackEncode, testData)
				:summarize(`MsgpackEncode {name}`)
		):print()

	bench(deserialize, serialize(testData))
		:withName(`Deserial {name}`)
		:updateOutput()
		-- Add task.wait() if supported
		:print()
		:compare(
			bench(jsonDecode, jsonEncode(testData))
				-- Add task.wait() if supported
				:withName(`JSONDecode {name}`),
			bench(msgpackDecode, msgpackEncode(testData))
				-- Add task.wait() if supported
				:withName(`MsgpackDecode {name}`)
		):print()
end

test(jsonDecode(require("./food-facts")), "Food Facts")
test(jsonDecode(require("./pokedex")), "Pokedex")
test(jsonDecode(require("./prize")), "Prize")