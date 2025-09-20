--!strict
-- Runs tests for ../BufferSerializer/string

local test = require("./test")

-- Check that string.luau works properly
local serialize = require("../src").serialize
local deserialize = require("../src").deserialize

local Sir_Empty = serialize("")
local Sir_Byte = serialize(string.rep("\0", 2^5))
local Sir_Char = serialize(string.rep("\0", 2^8))
local Sir_Tryte = serialize(string.rep("\0", 2^16))
local Sir_Int = serialize(string.rep("\0", 2^24))

-- serialization
test.serial(Sir_Empty, test.newBuffer(9))
test.serial(Sir_Byte, test.sizedBuffer(34, 10, 32))
test.serial(Sir_Char, test.sizedBuffer(259, 11, 0, 1))
test.serial(Sir_Tryte, test.sizedBuffer(65540, 12, 0, 0, 1))
test.serial(Sir_Int, test.sizedBuffer(16777221, 13, 0, 0, 0, 1))

-- deserialization
test.compare("", deserialize(Sir_Empty))
test.compare(string.rep("\0", 2^5), deserialize(Sir_Byte))
test.compare(string.rep("\0", 2^8), deserialize(Sir_Char))
test.compare(string.rep("\0", 2^16), deserialize(Sir_Tryte))
test.compare(string.rep("\0", 2^24), deserialize(Sir_Int))

-- constants [show risks]
local function ds(v: any): any 
	return deserialize(serialize(v))
end

local pair = require("../src").pair

-- Regular tests
pair(32, "1")
pair(64, "2")
pair(128, "3")
pair(1343, "4")

test.serial(serialize("1"), test.newBuffer(50))
test.serial(serialize("2"), test.newBuffer(82))
test.serial(serialize("3"), test.newBuffer(83, 64))
test.serial(serialize("4"), test.newBuffer(87, 255))

test.compare("1", ds("1"))
test.compare("2", ds("2"))
test.compare("3", ds("3"))
test.compare("4", ds("4"))

-- Serializes multiple values to the same id
--	To show that the latest is used
pair(1, "5")
pair(1, "6")

test.serial(serialize("5"), test.newBuffer(10, 1, 53))
test.compare("5", ds("5"))

test.serial(serialize("6"), test.newBuffer(19))
test.compare("6", ds("6"))

-- Serializes the same value to multiple ids
--	To show that the lastest is used
pair(33, "1") -- 32 -> 33

test.serial(serialize("1"), test.newBuffer(51))
test.compare("1", ds("1"))

-- Attempts to deserialize an invalid constant
--	50 is an previously valid string constant
--	Simulates migration from a value from 1 id to another
--		but failure to account for backwards compatibility
test.compare(nil, deserialize(test.newBuffer(50)))

-- Attempts to deserialize a value from before it was made a constant
local Sir_Seven = serialize("7")
pair(7, "7")
test.compare("7", deserialize(Sir_Seven)) -- nothing changes

-- Attempt to pair a constant string to a built-in string
-- built-in string [""] is of higher priority
test.compare(false, pcall(pair, 5, ""))

require("../src/string").resetRead()
require("../src/string").resetWrite()

test.complete("STRING")

return {}
