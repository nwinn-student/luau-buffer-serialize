--[[
	COMPONENT BENCHMARK - FOR - BUFFERSERIALIZER
	
	Notes:
	    Bench can be found at https://github.com/nwinn-student/luau-bench
	    Constitutes a set of benchmarks to run to ensure general performance does not degrade through versions
]]--

local bench = require("./Bench")
local benchPrecision = require("./Bench/Print").precision

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
	-- Add task.wait() if supported
	return self
end

function printType(name: string)
	print(` | {name} [s / kB / bytes]`)
end

local bufferSerial = require("./BufferSerializer")
local serialize = bufferSerial.serialize
local deserialize = bufferSerial.deserialize

local AMOUNT_RUN = 100

function runner(f: (...any)->(...any), input: any)
	for i=1, AMOUNT_RUN - 1 do
		f(input)
	end
	return f(input)
end
function drunner(f: (...any)->(...any), input: any)
	local serInput = serialize(input)
	for i=1, AMOUNT_RUN do
		f(serInput)
	end
end

-- It looks like testing, except I am not validating the result
print("SERIALIZING...")

printType("NIL")
bench(runner, serialize, nil):summarize("nil (0)")

printType("BOOLEAN")
bench(runner, serialize, true):summarize("truthy (1)")
bench(runner, serialize, false):summarize("falsy (2)")

printType("BUFFER")
bench(runner, serialize, buffer.create(0)):summarize("empty (3)")
bench(runner, serialize, buffer.create(2^0)):summarize("byte (4)")

printType("STRING")
bench(runner, serialize, ""):summarize("empty (9)")
bench(runner, serialize, string.rep(" ", 2^0)):summarize("byte (10)")

printType("NUMBER")
bench(runner, serialize, 0):summarize("zero (88)")
bench(runner, serialize, 1):summarize("one (89)")
bench(runner, serialize, 2^6):summarize("byte (90)")
bench(runner, serialize, 2^14):summarize("char (91)")
bench(runner, serialize, 2^22):summarize("tryte (92)")
bench(runner, serialize, 2^30):summarize("int (93)")
bench(runner, serialize, 2^-126):summarize("float (94)")
bench(runner, serialize, 2^-1022):summarize("double (95)")
bench(runner, serialize, 0 / 0):summarize("nan (96)")

printType("VECTOR")
bench(runner, serialize, vector.zero):summarize("zero (136)")
bench(runner, serialize, vector.one):summarize("one (137)")
bench(runner, serialize, vector.create(1,0,0)):summarize("x_axis (138)")
bench(runner, serialize, vector.create(0,1,0)):summarize("y_axis (139)")
bench(runner, serialize, vector.create(0,0,1)):summarize("z_axis (140)")
bench(runner, serialize, vector.create(1,1,0)):summarize("xy_axis (141)")
bench(runner, serialize, vector.create(1,0,1)):summarize("xz_axis (142)")
bench(runner, serialize, vector.create(0,1,1)):summarize("yz_axis (143)")
bench(runner, serialize, vector.create(2^1,2^2,2^3)):summarize("byte (144)")
bench(runner, serialize, vector.create(2^8,2^9,2^10)):summarize("char (145)")
bench(runner, serialize, vector.create(2^16,2^17,2^18)):summarize("tryte (146)")
bench(runner, serialize, vector.create(2^-1,2^-2,2^-3)):summarize("float (147)")
bench(runner, serialize, vector.create(2^1,2^8,2^16)):summarize("number (148)")
bench(runner, serialize, vector.create(2^5,2^5,0)):summarize("scalar_number (149)")

printType("SMALL TABLE")
bench(runner, serialize, {}):summarize("empty (194)")
bench(runner, serialize, {1, A=1}):summarize("table (195) {1, A=1}")
bench(runner, serialize, {1,2,3,4}):summarize("array (197) {1,2,3,4}")
bench(runner, serialize, {A=1, B=2, C=3, D=4}):summarize("dict (198) {A=1, B=2, C=3, D=4}")

printType("USERDATA")
-- We need to add support for certain userdata for it to not be this
bench(runner, serialize, newproxy()):summarize("nil (203)")


print("DESERIALIZING...")

printType("NIL")
bench(drunner, deserialize, nil):summarize("nil (0)")

printType("BOOLEAN")
bench(drunner, deserialize, true):summarize("truthy (1)")
bench(drunner, deserialize, false):summarize("falsy (2)")

printType("BUFFER")
bench(drunner, deserialize, buffer.create(0)):summarize("empty (3)")
bench(drunner, deserialize, buffer.create(2^0)):summarize("byte (4)")

printType("STRING")
bench(drunner, deserialize, ""):summarize("empty (9)")
bench(drunner, deserialize, string.rep(" ", 2^0)):summarize("byte (10)")

printType("NUMBER")
bench(drunner, deserialize, 0):summarize("zero (88)")
bench(drunner, deserialize, 1):summarize("one (89)")
bench(drunner, deserialize, 2^6):summarize("byte (90)")
bench(drunner, deserialize, 2^14):summarize("char (91)")
bench(drunner, deserialize, 2^22):summarize("tryte (92)")
bench(drunner, deserialize, 2^30):summarize("int (93)")
bench(drunner, deserialize, 2^-126):summarize("float (94)")
bench(drunner, deserialize, 2^-1022):summarize("double (95)")
bench(drunner, deserialize, 0 / 0):summarize("nan (96)")

printType("VECTOR")
bench(drunner, deserialize, vector.zero):summarize("zero (136)")
bench(drunner, deserialize, vector.one):summarize("one (137)")
bench(drunner, deserialize, vector.create(1,0,0)):summarize("x_axis (138)")
bench(drunner, deserialize, vector.create(0,1,0)):summarize("y_axis (139)")
bench(drunner, deserialize, vector.create(0,0,1)):summarize("z_axis (140)")
bench(drunner, deserialize, vector.create(1,1,0)):summarize("xy_axis (141)")
bench(drunner, deserialize, vector.create(1,0,1)):summarize("xz_axis (142)")
bench(drunner, deserialize, vector.create(0,1,1)):summarize("yz_axis (143)")
bench(drunner, deserialize, vector.create(2^1,2^2,2^3)):summarize("byte (144)")
bench(drunner, deserialize, vector.create(2^8,2^9,2^10)):summarize("char (145)")
bench(drunner, deserialize, vector.create(2^16,2^17,2^18)):summarize("tryte (146)")
bench(drunner, deserialize, vector.create(2^-1,2^-2,2^-3)):summarize("float (147)")
bench(drunner, deserialize, vector.create(2^1,2^8,2^16)):summarize("number (148)")
bench(drunner, deserialize, vector.create(2^5,2^5,0)):summarize("scalar_number (149)")

printType("SMALL TABLE")
bench(drunner, deserialize, {}):summarize("empty (194)")
bench(drunner, deserialize, {1, A=1}):summarize("table (195) {1, A=1}")
bench(drunner, deserialize, {1,2,3,4}):summarize("array (197) {1,2,3,4}")
bench(drunner, deserialize, {A=1, B=2, C=3, D=4}):summarize("dict (198) {A=1, B=2, C=3, D=4}")

printType("USERDATA")
-- We need to add support for certain userdata for it to not be this
bench(drunner, deserialize, newproxy()):summarize("nil (203)")
