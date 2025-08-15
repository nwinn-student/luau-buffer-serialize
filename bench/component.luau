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

local bufferSerial = require("./BufferSerializer/BufferSerializer")
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

printType("NUMBER")
bench(serialize, 0):summarize("zero (88)")
bench(serialize, 1):summarize("one (89)")
bench(serialize, 2^6):summarize("byte (90)")
bench(serialize, 2^14):summarize("char (91)")
bench(serialize, 2^22):summarize("tryte (92)")
bench(serialize, 2^30):summarize("int (93)")
bench(serialize, 2^-126):summarize("float (94)")
bench(serialize, 2^-1022):summarize("double (95)")
bench(serialize, 0 / 0):summarize("nan (96)")

printType("VECTOR")
bench(serialize, vector.zero):summarize("zero (136)")
bench(serialize, vector.one):summarize("one (137)")
bench(serialize, vector.create(1,0,0)):summarize("x_axis (138)")
bench(serialize, vector.create(0,1,0)):summarize("y_axis (139)")
bench(serialize, vector.create(0,0,1)):summarize("z_axis (140)")
bench(serialize, vector.create(1,1,0)):summarize("xy_axis (141)")
bench(serialize, vector.create(1,0,1)):summarize("xz_axis (142)")
bench(serialize, vector.create(0,1,1)):summarize("yz_axis (143)")
bench(serialize, vector.create(2^1,2^2,2^3)):summarize("byte (144)")
bench(serialize, vector.create(2^8,2^9,2^10)):summarize("char (145)")
bench(serialize, vector.create(2^16,2^17,2^18)):summarize("tryte (146)")
bench(serialize, vector.create(2^-1,2^-2,2^-3)):summarize("float (147)")
bench(serialize, vector.create(2^1,2^8,2^16)):summarize("number (148)")
bench(serialize, vector.create(2^5,2^5,0)):summarize("scalar_number (149)")

printType("TABLE")
bench(serialize, {}):summarize("empty (194)")
bench(serialize, {1, A = 1}):summarize("table (195)")
-- Says that the element already exists in the table
bench(serialize, {5, 5}):summarize("existing (196)")
bench(serialize, {1}):summarize("array (197)")
bench(serialize, {A = 1}):summarize("dict (198)")
-- Says the array section of the **table** has ended
bench(serialize, {1, --[[ ARRAY_END ]] A = 1}):summarize("array_end (199)")
-- Says the table has ended, whether array, dict, or table
bench(serialize, {1 --[[ TABLE_END ]]}):summarize("table_end (200)")

printType("USERDATA")
-- We need to add support for certain userdata for it to not be this
bench(serialize, newproxy()):summarize("nil (203)")


print("DESERIALIZING...")

printType("NIL")
bench(deserialize, serialize(nil)):summarize("nil (0)")

printType("BOOLEAN")
bench(deserialize, serialize(true)):summarize("truthy (1)")
bench(deserialize, serialize(false)):summarize("falsy (2)")

printType("BUFFER")
bench(deserialize, serialize(buffer.create(0))):summarize("empty (3)")
bench(deserialize, serialize(buffer.create(2^0))):summarize("byte (4)")
bench(deserialize, serialize(buffer.create(2^8))):summarize("char (5)")
bench(deserialize, serialize(buffer.create(2^16))):summarize("tryte (6)")
bench(deserialize, serialize(buffer.create(2^24))):summarize("int (7)")

printType("STRING")
bench(deserialize, serialize("")):summarize("empty (9)")
bench(deserialize, serialize(string.rep(" ", 2^0))):summarize("byte (10)")
bench(deserialize, serialize(string.rep(" ", 2^8))):summarize("char (11)")
bench(deserialize, serialize(string.rep(" ", 2^16))):summarize("tryte (12)")
bench(deserialize, serialize(string.rep(" ", 2^24))):summarize("int (13)")

printType("NUMBER")
bench(deserialize, serialize(0)):summarize("zero (88)")
bench(deserialize, serialize(1)):summarize("one (89)")
bench(deserialize, serialize(2^6)):summarize("byte (90)")
bench(deserialize, serialize(2^14)):summarize("char (91)")
bench(deserialize, serialize(2^22)):summarize("tryte (92)")
bench(deserialize, serialize(2^30)):summarize("int (93)")
bench(deserialize, serialize(2^-126)):summarize("float (94)")
bench(deserialize, serialize(2^-1022)):summarize("double (95)")
bench(deserialize, serialize(0 / 0)):summarize("nan (96)")

printType("VECTOR")
bench(deserialize, serialize(vector.zero)):summarize("zero (136)")
bench(deserialize, serialize(vector.one)):summarize("one (137)")
bench(deserialize, serialize(vector.create(1,0,0))):summarize("x_axis (138)")
bench(deserialize, serialize(vector.create(0,1,0))):summarize("y_axis (139)")
bench(deserialize, serialize(vector.create(0,0,1))):summarize("z_axis (140)")
bench(deserialize, serialize(vector.create(1,1,0))):summarize("xy_axis (141)")
bench(deserialize, serialize(vector.create(1,0,1))):summarize("xz_axis (142)")
bench(deserialize, serialize(vector.create(0,1,1))):summarize("yz_axis (143)")
bench(deserialize, serialize(vector.create(2^1,2^2,2^3))):summarize("byte (144)")
bench(deserialize, serialize(vector.create(2^8,2^9,2^10))):summarize("char (145)")
bench(deserialize, serialize(vector.create(2^16,2^17,2^18))):summarize("tryte (146)")
bench(deserialize, serialize(vector.create(2^-1,2^-2,2^-3))):summarize("float (147)")
bench(deserialize, serialize(vector.create(2^1,2^8,2^16))):summarize("number (148)")
bench(deserialize, serialize(vector.create(2^5,2^5,0))):summarize("scalar_number (149)")

printType("TABLE")
bench(deserialize, serialize({})):summarize("empty (194)")
bench(deserialize, serialize({1, A = 1})):summarize("table (195)")
-- Says that the element already exists in the table
bench(deserialize, serialize({5, 5})):summarize("existing (196)")
bench(deserialize, serialize({1})):summarize("array (197)")
bench(deserialize, serialize({A = 1})):summarize("dict (198)")
-- Says the array section of the **table** has ended
bench(deserialize, serialize({1, --[[ ARRAY_END ]] A = 1})):summarize("array_end (199)")
-- Says the table has ended, whether array, dict, or table
bench(deserialize, serialize({1 --[[ TABLE_END ]]})):summarize("table_end (200)")

printType("USERDATA")
-- We need to add support for certain userdata for it to not be this
bench(deserialize, serialize(newproxy())):summarize("nil (203)")
