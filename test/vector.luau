--!strict
-- Runs tests for ../BufferSerializer/vector

local test = require("./test")
local vcreate = vector.create
local ZERO = 136
local ONE = 137
local X = 138
local Y = 139
local Z = 140
local XY = 141
local XZ = 142
local YZ = 143
local BYTE = 144
local CHAR = 145
local TRYTE = 146
local FLOAT = 147
local NUMBER = 148
local SCALAR = 149
local CONST_INIT = 157
local CONST_NEXT = 190

-- Check that vector.luau works properly
local serialize = require("../src").serialize
local deserialize = require("../src").deserialize

local Sir_Zero = serialize(vector.zero)
local Sir_One = serialize(vector.one)
local Sir_X = serialize(vcreate(1,0))
local Sir_Y = serialize(vcreate(0,1))
local Sir_Z = serialize(vcreate(0,0,1))
local Sir_XY = serialize(vcreate(1,1))
local Sir_XZ = serialize(vcreate(1,0,1))
local Sir_YZ = serialize(vcreate(0,1,1))
local Sir_Byte = serialize(vcreate(2,3,4))
local Sir_Char = serialize(vcreate(2^8,2^9,2^10))
local Sir_Tryte = serialize(vcreate(2^16,2^17,2^18))
local Sir_Float = serialize(vcreate(2^24,2^25,2^26))
local Sir_Number = serialize(vcreate(2,2^8,2^16))
local Sir_Scalar = serialize(vcreate(2,0,0))

-- serialization
test.serial(Sir_Zero, test.newBuffer(ZERO))
test.serial(Sir_One, test.newBuffer(ONE))
test.serial(Sir_X, test.newBuffer(X))
test.serial(Sir_Y, test.newBuffer(Y))
test.serial(Sir_Z, test.newBuffer(Z))
test.serial(Sir_XY, test.newBuffer(XY))
test.serial(Sir_XZ, test.newBuffer(XZ))
test.serial(Sir_YZ, test.newBuffer(YZ))
test.serial(Sir_Byte, test.newBuffer(BYTE,2,3,4))
test.serial(Sir_Char, test.newBuffer(CHAR,0,1,0,2,0,4))
test.serial(Sir_Tryte, test.newBuffer(TRYTE,0,0,1,0,0,2,0,0,4))
test.serial(Sir_Float, test.newBuffer(FLOAT,0,0,128,75,0,0,0,76,0,0,128,76))
test.serial(Sir_Number, test.newBuffer(NUMBER,90,2,91,0,1,92,0,0,1))
test.serial(Sir_Scalar, test.newBuffer(SCALAR,138,90,2))

-- deserialization
test.compare(vector.zero, deserialize(Sir_Zero))
test.compare(vector.one, deserialize(Sir_One))
test.compare(vcreate(1,0), deserialize(Sir_X))
test.compare(vcreate(0,1), deserialize(Sir_Y))
test.compare(vcreate(0,0,1), deserialize(Sir_Z))
test.compare(vcreate(1,1), deserialize(Sir_XY))
test.compare(vcreate(1,0,1), deserialize(Sir_XZ))
test.compare(vcreate(0,1,1), deserialize(Sir_YZ))
test.compare(vcreate(2,3,4), deserialize(Sir_Byte))
test.compare(vcreate(2^8,2^9,2^10), deserialize(Sir_Char))
test.compare(vcreate(2^16,2^17,2^18), deserialize(Sir_Tryte))
test.compare(vcreate(2^24,2^25,2^26), deserialize(Sir_Float))
test.compare(vcreate(2,2^8,2^16), deserialize(Sir_Number))
test.compare(vcreate(2,0,0), deserialize(Sir_Scalar))

-- constants [show risks]
local function ds(v: any): any 
	return deserialize(serialize(v))
end

local pair = require("../src").pair

-- Regular tests
pair(16, vcreate(1,2,3))
pair(32, vcreate(2,2,2))
pair(32 + 96, vcreate(3,3,3)) -- 128
pair(32 + 4*256 - 1, vcreate(4,4,4)) -- 1055

test.serial(serialize(vcreate(1,2,3)), test.newBuffer(CONST_INIT + 16))
test.serial(serialize(vcreate(2,2,2)), test.newBuffer(CONST_INIT + 32))
test.serial(serialize(vcreate(3,3,3)), test.newBuffer(CONST_NEXT, 96))
test.serial(serialize(vcreate(4,4,4)), test.newBuffer(CONST_NEXT + 3, 255))

test.compare(vcreate(1,2,3), ds(vcreate(1,2,3)))
test.compare(vcreate(2,2,2), ds(vcreate(2,2,2)))
test.compare(vcreate(3,3,3), ds(vcreate(3,3,3)))
test.compare(vcreate(4,4,4), ds(vcreate(4,4,4)))

-- Serializes multiple values to the same id
--	To show that the latest is used
pair(1, vcreate(5,5,5))
pair(1, vcreate(6,6,6))

test.serial(serialize(vcreate(5,5,5)), test.newBuffer(SCALAR, 137, 90, 5))
test.compare(vcreate(5,5,5), ds(vcreate(5,5,5)))

test.serial(serialize(vcreate(6,6,6)), test.newBuffer(CONST_INIT + 1))
test.compare(vcreate(6,6,6), ds(vcreate(6,6,6)))

-- Serializes the same value to multiple ids
--	To show that the lastest is used
pair(33, vcreate(2,2,2)) -- 32 -> 33

test.serial(serialize(vcreate(2,2,2)), test.newBuffer(CONST_NEXT, 1))
test.compare(vcreate(2,2,2), ds(vcreate(2,2,2)))

-- Attempts to deserialize an invalid constant
--	CONST_INIT + 32 is an previously valid vector constant
--	Simulates migration from a value from 1 id to another
--		but failure to account for backwards compatibility
test.compare(nil, deserialize(test.newBuffer(CONST_INIT + 32)))

-- Attempts to deserialize a value from before it was made a constant
local Sir_Seven = serialize(vcreate(7,7,7))
pair(7, vcreate(7,7,7))
test.compare(vcreate(7,7,7), deserialize(Sir_Seven)) -- nothing changes

-- Attempt to pair a constant vector to a built-in vector
-- built-in vector [vector.zero] is of higher priority
test.compare(false, pcall(pair, 5, vector.zero))

require("../src/vector").resetRead()
require("../src/vector").resetWrite()

test.complete("VECTOR")

return {}
