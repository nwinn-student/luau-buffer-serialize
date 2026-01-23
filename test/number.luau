--!strict
-- Runs tests for ../src/number

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

-- Check that number.luau works properly
local serialize = require("../src").serialize
local deserialize = require("../src").deserialize

local Sir_Zero = serialize(0)
local Sir_One = serialize(1)
local Sir_Byte = serialize(2 ^ 1)
local Sir_Char = serialize(2 ^ 8)
local Sir_Tryte = serialize(2 ^ 16)
local Sir_InvTryte = serialize(-2 ^ 16)
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
test.serial(Sir_InvTryte, test.newBuffer(TRYTE, 0, 0, 255))
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
test.compare(-2 ^ 16, deserialize(Sir_InvTryte))
test.compare(2 ^ 24, deserialize(Sir_Int))
test.compare(2 ^ -8, deserialize(Sir_Float))
test.compare(2 ^ -256, deserialize(Sir_Double))
test.compare(0 / 0, deserialize(Sir_NaN))

-- error checks
local numDeserialize = require("../src/number").deserialize
test.compare(false, pcall(numDeserialize, test.newBuffer(0), 0)) -- failure to parse

return {}
