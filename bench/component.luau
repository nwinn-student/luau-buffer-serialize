--[[
	COMPONENT BENCHMARK - FOR - BUFFERSERIALIZER
		
	Notes:
	    Bench can be found at https://github.com/nwinn-student/luau-bench
	    Constitutes a set of benchmarks to run to ensure general performance does not degrade
]]--

local bench = require("./Bench/Bench")
local benchPrecision = require("./Bench/internal/Print").precision

local benchMethods = getmetatable(bench(function() end)).__index

--[[
	We expect:
 | TYPE [s / kB / bytes]
    | APPROACH
      MEDIAN_SPEED AVG_MEM SIZE
    | APPROACH
      MEDIAN_SPEED AVG_MEM SIZE
    | APPROACH
      MEDIAN_SPEED AVG_MEM SIZE
    | APPROACH
      MEDIAN_SPEED AVG_MEM SIZE
...
]]--
function benchMethods:summarize(approach: string)
	self.Name = approach
	
	local str = `    | {approach}\n      {
		benchPrecision(self.Speed.Median, 4)
	} {
		benchPrecision(self.Memory.Average, 4)
	}`
	
	local typeOutput = type(self.Output)
	if typeOutput == "buffer" then
		str ..= ` { buffer.len(self.Output) }`
	end
	print(str)
	return self
end

function printType(name: string)
	print(` | {name} [s / kB / bytes]`)
end

local bufferSerial = require("./BufferSerializer/Serialize")
local serialize = bufferSerial.serialize
local deserialize = bufferSerial.deserialize

-- It looks like testing, except I am not validating the result
print("SERIALIZING...")

printType("NIL")
bench(serialize, nil):summarize("nil (0)")

printType("BOOLEAN")
bench(serialize, true):summarize("truthy (1)")
bench(serialize, false):summarize("falsy (2)")

printType("BUFFER")
bench(serialize, buffer.create(0)):summarize("empty (3)")
bench(serialize, buffer.create(2^0)):summarize("byte (4)")
bench(serialize, buffer.create(2^8)):summarize("char (5)")
bench(serialize, buffer.create(2^16)):summarize("tryte (6)")
bench(serialize, buffer.create(2^24)):summarize("int (7)")


printType("STRING")
bench(serialize, ""):summarize("empty (9)")
bench(serialize, string.rep(" ", 2^0)):summarize("byte (10)")
bench(serialize, string.rep(" ", 2^8)):summarize("char (11)")
bench(serialize, string.rep(" ", 2^16)):summarize("tryte (12)")
bench(serialize, string.rep(" ", 2^24)):summarize("int (13)")
-- Other aspects are also present, specifically for small numbers and those that start w/ 0
bench(serialize, "Hello_12345"):summarize("concatsn (14)")
bench(serialize, "12345_Hello"):summarize("concatns (15)")
bench(serialize, "12345"):summarize("num (16)")

printType("NUMBER")
bench(serialize, 0):summarize("zero (88)")

print("DESERIALIZING...")