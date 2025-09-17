--!strict
-- Runs tests for ../BufferSerializer/vector

local test = require("./test")

-- Check that vector.luau works properly
local vecSerialize = test.newSerializer(vector.one)
local vecDeserialize = test.newDeserializer(vector.one)

local Sir_Zero = vecSerialize(vector.zero)
local Sir_One = vecSerialize(vector.one)
local Sir_X = vecSerialize(vector.create(1,0))
local Sir_Y = vecSerialize(vector.create(0,1))
local Sir_Z = vecSerialize(vector.create(0,0,1))
local Sir_XY = vecSerialize(vector.create(1,1))
local Sir_XZ = vecSerialize(vector.create(1,0,1))
local Sir_YZ = vecSerialize(vector.create(0,1,1))
local Sir_Byte = vecSerialize(vector.create(2,3,4))
local Sir_Char = vecSerialize(vector.create(2^8,2^9,2^10))
local Sir_Tryte = vecSerialize(vector.create(2^16,2^17,2^18))
local Sir_Float = vecSerialize(vector.create(2^24,2^25,2^26))
local Sir_Number = vecSerialize(vector.create(2,2^8,2^16))
local Sir_Scalar = vecSerialize(vector.create(2,0,0))

-- serialization
test.serial(Sir_Zero, test.newBuffer(136))
test.serial(Sir_One, test.newBuffer(137))
test.serial(Sir_X, test.newBuffer(138))
test.serial(Sir_Y, test.newBuffer(139))
test.serial(Sir_Z, test.newBuffer(140))
test.serial(Sir_XY, test.newBuffer(141))
test.serial(Sir_XZ, test.newBuffer(142))
test.serial(Sir_YZ, test.newBuffer(143))
test.serial(Sir_Byte, test.newBuffer(144,2,3,4))
test.serial(Sir_Char, test.newBuffer(145,0,1,0,2,0,4))
test.serial(Sir_Tryte, test.newBuffer(146,0,0,1,0,0,2,0,0,4))
test.serial(Sir_Float, test.newBuffer(147,0,0,128,75,0,0,0,76,0,0,128,76))
test.serial(Sir_Number, test.sizedBuffer(16, 148,90,2,91,0,1,92,0,0,1))
test.serial(Sir_Scalar, test.newBuffer(149,138,90,2,0,0))

-- deserialization
test.compare(vector.zero, vecDeserialize(Sir_Zero))
test.compare(vector.one, vecDeserialize(Sir_One))
test.compare(vector.create(1,0), vecDeserialize(Sir_X))
test.compare(vector.create(0,1), vecDeserialize(Sir_Y))
test.compare(vector.create(0,0,1), vecDeserialize(Sir_Z))
test.compare(vector.create(1,1), vecDeserialize(Sir_XY))
test.compare(vector.create(1,0,1), vecDeserialize(Sir_XZ))
test.compare(vector.create(0,1,1), vecDeserialize(Sir_YZ))
test.compare(vector.create(2,3,4), vecDeserialize(Sir_Byte))
test.compare(vector.create(2^8,2^9,2^10), vecDeserialize(Sir_Char))
test.compare(vector.create(2^16,2^17,2^18), vecDeserialize(Sir_Tryte))
test.compare(vector.create(2^24,2^25,2^26), vecDeserialize(Sir_Float))
test.compare(vector.create(2,2^8,2^16), vecDeserialize(Sir_Number))
test.compare(vector.create(2,0,0), vecDeserialize(Sir_Scalar))


-- Check that init.luau works with vector.luau properly
local serialize = require("../src").serialize
local deserialize = require("../src").deserialize

Sir_Zero = serialize(vector.zero)
Sir_One = serialize(vector.one)
Sir_X = serialize(vector.create(1,0))
Sir_Y = serialize(vector.create(0,1))
Sir_Z = serialize(vector.create(0,0,1))
Sir_XY = serialize(vector.create(1,1))
Sir_XZ = serialize(vector.create(1,0,1))
Sir_YZ = serialize(vector.create(0,1,1))
Sir_Byte = serialize(vector.create(2,3,4))
Sir_Char = serialize(vector.create(2^8,2^9,2^10))
Sir_Tryte = serialize(vector.create(2^16,2^17,2^18))
Sir_Float = serialize(vector.create(2^24,2^25,2^26))
Sir_Number = serialize(vector.create(2,2^8,2^16))
Sir_Scalar = serialize(vector.create(2,0,0))

-- serialization
test.serial(Sir_Zero, test.newBuffer(136))
test.serial(Sir_One, test.newBuffer(137))
test.serial(Sir_X, test.newBuffer(138))
test.serial(Sir_Y, test.newBuffer(139))
test.serial(Sir_Z, test.newBuffer(140))
test.serial(Sir_XY, test.newBuffer(141))
test.serial(Sir_XZ, test.newBuffer(142))
test.serial(Sir_YZ, test.newBuffer(143))
test.serial(Sir_Byte, test.newBuffer(144,2,3,4))
test.serial(Sir_Char, test.newBuffer(145,0,1,0,2,0,4))
test.serial(Sir_Tryte, test.newBuffer(146,0,0,1,0,0,2,0,0,4))
test.serial(Sir_Float, test.newBuffer(147,0,0,128,75,0,0,0,76,0,0,128,76))
test.serial(Sir_Number, test.newBuffer(148,90,2,91,0,1,92,0,0,1))
test.serial(Sir_Scalar, test.newBuffer(149,138,90,2))

-- deserialization
test.compare(vector.zero, deserialize(Sir_Zero))
test.compare(vector.one, deserialize(Sir_One))
test.compare(vector.create(1,0), deserialize(Sir_X))
test.compare(vector.create(0,1), deserialize(Sir_Y))
test.compare(vector.create(0,0,1), deserialize(Sir_Z))
test.compare(vector.create(1,1), deserialize(Sir_XY))
test.compare(vector.create(1,0,1), deserialize(Sir_XZ))
test.compare(vector.create(0,1,1), deserialize(Sir_YZ))
test.compare(vector.create(2,3,4), deserialize(Sir_Byte))
test.compare(vector.create(2^8,2^9,2^10), deserialize(Sir_Char))
test.compare(vector.create(2^16,2^17,2^18), deserialize(Sir_Tryte))
test.compare(vector.create(2^24,2^25,2^26), deserialize(Sir_Float))
test.compare(vector.create(2,2^8,2^16), deserialize(Sir_Number))
test.compare(vector.create(2,0,0), deserialize(Sir_Scalar))

-- constants [show risks]
local function ds(v: any): any 
	return deserialize(serialize(v))
end

local pair = require("../src").pair

-- Regular tests
pair(16, vector.create(1,2,3))
pair(32, vector.create(2,2,2))
pair(128, vector.create(3,3,3))
pair(1055, vector.create(4,4,4))

test.serial(serialize(vector.create(1,2,3)), test.newBuffer(173))
test.serial(serialize(vector.create(2,2,2)), test.newBuffer(189))
test.serial(serialize(vector.create(3,3,3)), test.newBuffer(190, 96))
test.serial(serialize(vector.create(4,4,4)), test.newBuffer(193, 255))

test.compare(vector.create(1,2,3), ds(vector.create(1,2,3)))
test.compare(vector.create(2,2,2), ds(vector.create(2,2,2)))
test.compare(vector.create(3,3,3), ds(vector.create(3,3,3)))
test.compare(vector.create(4,4,4), ds(vector.create(4,4,4)))

-- Serializes multiple values to the same id
--	To show that the latest is used
pair(1, vector.create(5,5,5))
pair(1, vector.create(6,6,6))

test.serial(serialize(vector.create(5,5,5)), test.newBuffer(149, 137, 90, 5))
test.compare(vector.create(5,5,5), ds(vector.create(5,5,5)))

test.serial(serialize(vector.create(6,6,6)), test.newBuffer(158))
test.compare(vector.create(6,6,6), ds(vector.create(6,6,6)))

-- Serializes the same value to multiple ids
--	To show that the lastest is used
pair(33, vector.create(1,2,3)) -- 32 -> 33

test.serial(serialize(vector.create(1,2,3)), test.newBuffer(190, 1))
test.compare(vector.create(1,2,3), ds(vector.create(1,2,3)))

-- Attempts to deserialize an invalid constant
--	50 is an previously valid vector constant
--	Simulates migration from a value from 1 id to another
--		but failure to account for backwards compatibility
test.compare(nil, deserialize(test.newBuffer(50)))

-- Attempts to deserialize a value from before it was made a constant
local Sir_Seven = serialize(vector.create(7,7,7))
pair(7, vector.create(7,7,7))
test.compare(vector.create(7,7,7), deserialize(Sir_Seven)) -- nothing changes

-- Attempt to pair a constant vector to a built-in vector
-- built-in vector [vector.zero] is of higher priority
test.compare(false, pcall(pair, 5, vector.zero))

require("../src/vector").resetRead()
require("../src/vector").resetWrite()

test.complete("VECTOR")

return {}
