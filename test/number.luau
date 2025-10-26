--!strict
-- Runs tests for ../BufferSerializer/number

local test = require("./test")
local ZERO = 88
local ONE = 89
local BYTE = 90
local CHAR = 91
local TRYTE = 92
local INT = 93
local FLOAT = 94
local DOUBLE = 95
local NAN = 96
local CONST_INIT = 99
local CONST_NEXT = 132

-- Check that number.luau works properly
local serialize = require("../src").serialize
local deserialize = require("../src").deserialize

local Sir_Zero = serialize(0)
local Sir_One = serialize(1)
local Sir_Byte = serialize(2 ^ 1)
local Sir_Char = serialize(2 ^ 8)
local Sir_Tryte = serialize(2 ^ 16)
local Sir_Int = serialize(2 ^ 24)
local Sir_Float = serialize(2 ^ -8)
local Sir_Double = serialize(2 ^ -256)
local Sir_NaN = serialize(0 / 0)

-- serialization
test.serial(Sir_Zero, test.newBuffer(ZERO))
test.serial(Sir_One, test.newBuffer(ONE))
test.serial(Sir_Byte, test.newBuffer(BYTE, 2 ^ 1))
test.serial(Sir_Char, test.newBuffer(CHAR, 0, 1))
test.serial(Sir_Tryte, test.newBuffer(TRYTE, 0, 0, 1))
test.serial(Sir_Int, test.newBuffer(INT, 0, 0, 0, 1))
test.serial(Sir_Float, test.newBuffer(FLOAT, 0, 0, 128, 59))
test.serial(Sir_Double, test.newBuffer(DOUBLE, 0, 0, 0, 0, 0, 0, 240, 47))
test.serial(Sir_NaN, test.newBuffer(NAN))

-- deserialization
test.compare(0, deserialize(Sir_Zero))
test.compare(1, deserialize(Sir_One))
test.compare(2 ^ 1, deserialize(Sir_Byte))
test.compare(2 ^ 8, deserialize(Sir_Char))
test.compare(2 ^ 16, deserialize(Sir_Tryte))
test.compare(2 ^ 24, deserialize(Sir_Int))
test.compare(2 ^ -8, deserialize(Sir_Float))
test.compare(2 ^ -256, deserialize(Sir_Double))
test.compare(0 / 0, deserialize(Sir_NaN))

-- constants [show risks]
local function ds(v: any): any
	return deserialize(serialize(v))
end

local pair = require("../src").pair

-- Regular tests
pair(16, 2)
pair(32, 3)
pair(32 + 96, 4) -- 128
pair(32 + 4 * 256 - 1, 5) -- 1055

test.serial(serialize(2), test.newBuffer(CONST_INIT + 16))
test.serial(serialize(3), test.newBuffer(CONST_INIT + 32))
test.serial(serialize(4), test.newBuffer(CONST_NEXT, 96))
test.serial(serialize(5), test.newBuffer(CONST_NEXT + 3, 255))

test.compare(2, ds(2))
test.compare(3, ds(3))
test.compare(4, ds(4))
test.compare(5, ds(5))

-- Serializes multiple values to the same id
--	To show that the latest is used
pair(1, 6)
pair(1, 7)

test.serial(serialize(6), test.newBuffer(BYTE, 6))
test.compare(6, ds(6))

test.serial(serialize(7), test.newBuffer(CONST_INIT + 1))
test.compare(7, ds(7))

-- Serializes the same value to multiple ids
--	To show that the lastest is used
pair(17, 2) -- 16 -> 17

test.serial(serialize(2), test.newBuffer(CONST_INIT + 17))
test.compare(2, ds(2))

-- Attempts to deserialize an invalid constant
--	CONST_INIT + 16 is an previously valid number constant
--	Simulates migration from a value from 1 id to another
--		but failure to account for backwards compatibility
test.compare(nil, deserialize(test.newBuffer(CONST_INIT + 16)))

-- Attempts to deserialize a value from before it was made a constant
local Sir_Eight = serialize(8)
pair(7, 8)
test.compare(8, deserialize(Sir_Eight)) -- nothing changes

-- Attempt to pair a constant number to a built-in number
-- built-in number [1] is of higher priority
test.compare(false, pcall(pair, 5, 1))

return {}
