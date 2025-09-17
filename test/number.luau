--!strict
-- Runs tests for ../BufferSerializer/number

local test = require("./test")

-- Check that number.luau works properly
local numSerialize = require("../src/number").serialize
local numDeserialize = require("../src/number").deserialize

local Sir_Zero = numSerialize(0, buffer.create(1), 0, 1)
local Sir_One = numSerialize(1, buffer.create(1), 0, 1)
local Sir_Byte = numSerialize(2^1, buffer.create(1), 0, 1)
local Sir_Char = numSerialize(2^8, buffer.create(1), 0, 1)
local Sir_Tryte = numSerialize(2^16, buffer.create(1), 0, 1)
local Sir_Int = numSerialize(2^24, buffer.create(1), 0, 1)
local Sir_Float = numSerialize(2^-8, buffer.create(1), 0, 1)
local Sir_Double = numSerialize(2^-256, buffer.create(1), 0, 1)
local Sir_NaN = numSerialize(0/0, buffer.create(1), 0, 1)

-- serialization
test.serial(Sir_Zero, test.newBuffer(88))
test.serial(Sir_One, test.newBuffer(89))
test.serial(Sir_Byte, test.newBuffer(90, 2^1))
test.serial(Sir_Char, test.sizedBuffer(4, 91, 0, 1))
test.serial(Sir_Tryte, test.sizedBuffer(4, 92, 0, 0, 1))
test.serial(Sir_Int, test.sizedBuffer(8, 93, 0, 0, 0, 1))
test.serial(Sir_Float, test.sizedBuffer(8, 94, 0, 0, 128, 59))
test.serial(Sir_Double, test.sizedBuffer(16, 95, 0, 0, 0, 0 ,0, 0, 240, 47))
test.serial(Sir_NaN, test.newBuffer(96))

-- deserialization
test.compare(0, numDeserialize(Sir_Zero, 0))
test.compare(1, numDeserialize(Sir_One, 0))
test.compare(2^1, numDeserialize(Sir_Byte, 0))
test.compare(2^8, numDeserialize(Sir_Char, 0))
test.compare(2^16, numDeserialize(Sir_Tryte, 0))
test.compare(2^24, numDeserialize(Sir_Int, 0))
test.compare(2^-8, numDeserialize(Sir_Float, 0))
test.compare(2^-256, numDeserialize(Sir_Double, 0))
test.compare(0/0, numDeserialize(Sir_NaN, 0))

-- Check that init.luau works with number.luau properly
local serialize = require("../src").serialize
local deserialize = require("../src").deserialize

Sir_Zero = serialize(0)
Sir_One = serialize(1)
Sir_Byte = serialize(2^1)
Sir_Char = serialize(2^8)
Sir_Tryte = serialize(2^16)
Sir_Int = serialize(2^24)
Sir_Float = serialize(2^-8)
Sir_Double = serialize(2^-256)
Sir_NaN = serialize(0/0)

-- serialization
test.serial(Sir_Zero, test.newBuffer(88))
test.serial(Sir_One, test.newBuffer(89))
test.serial(Sir_Byte, test.newBuffer(90, 2^1))
test.serial(Sir_Char, test.newBuffer(91, 0, 1))
test.serial(Sir_Tryte, test.newBuffer(92, 0, 0, 1))
test.serial(Sir_Int, test.newBuffer(93, 0, 0, 0, 1))
test.serial(Sir_Float, test.newBuffer(94, 0, 0, 128, 59))
test.serial(Sir_Double, test.newBuffer(95, 0, 0, 0, 0 ,0, 0, 240, 47))
test.serial(Sir_NaN, test.newBuffer(96))

-- deserialization
test.compare(0, deserialize(Sir_Zero))
test.compare(1, deserialize(Sir_One))
test.compare(2^1, deserialize(Sir_Byte))
test.compare(2^8, deserialize(Sir_Char))
test.compare(2^16, deserialize(Sir_Tryte))
test.compare(2^24, deserialize(Sir_Int))
test.compare(2^-8, deserialize(Sir_Float))
test.compare(2^-256, deserialize(Sir_Double))
test.compare(0/0, deserialize(Sir_NaN))

-- constants [show risks]
local function ds(v: any): any 
	return deserialize(serialize(v))
end

local pair = require("../src").pair

-- Regular tests
pair(16, 2)
pair(32, 3)
pair(128, 4)
pair(1055, 5)

test.serial(serialize(2), test.newBuffer(115))
test.serial(serialize(3), test.newBuffer(131))
test.serial(serialize(4), test.newBuffer(132, 96))
test.serial(serialize(5), test.newBuffer(135, 255))

test.compare(2, ds(2))
test.compare(3, ds(3))
test.compare(4, ds(4))
test.compare(5, ds(5))

-- Serializes multiple values to the same id
--	To show that the latest is used
pair(1, 6)
pair(1, 7)

test.serial(serialize(6), test.newBuffer(90, 6))
test.compare(6, ds(6))

test.serial(serialize(7), test.newBuffer(100))
test.compare(7, ds(7))

-- Serializes the same value to multiple ids
--	To show that the lastest is used
pair(17, 2) -- 16 -> 17

test.serial(serialize(2), test.newBuffer(116))
test.compare(2, ds(2))

-- Attempts to deserialize an invalid constant
--	50 is an previously valid number constant
--	Simulates migration from a value from 1 id to another
--		but failure to account for backwards compatibility
test.compare(nil, deserialize(test.newBuffer(115)))

-- Attempts to deserialize a value from before it was made a constant
local Sir_Eight = serialize(8)
pair(7, 8)
test.compare(8, deserialize(Sir_Eight)) -- nothing changes

-- Attempt to pair a constant number to a built-in number
-- built-in number [1] is of higher priority
test.compare(false, pcall(pair, 5, 1))

test.complete("NUMBER")

return {}
