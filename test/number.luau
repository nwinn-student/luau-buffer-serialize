--!strict
-- Runs tests for ../src/number

local test = require("./test")
local ZERO = 97
local ONE = 98
local BYTE = 99
local CHAR = 100
local TRYTE = 101
local INT = 102
local FLOAT = 103
local DOUBLE = 104
local NAN = 105

-- Check that number.luau works properly
test.compare(test.newBuffer(ZERO), test.inspect(0))
test.compare(test.newBuffer(ONE), test.inspect(1))
test.compare(test.newBuffer(BYTE, 2 ^ 1), test.inspect(2 ^ 1))
test.compare(test.newBuffer(CHAR, 0, 1), test.inspect(2 ^ 8))
test.compare(test.newBuffer(TRYTE, 0, 0, 1), test.inspect(2 ^ 16))
test.compare(test.newBuffer(TRYTE, 0, 0, 255), test.inspect(-2 ^ 16))
test.compare(test.newBuffer(INT, 0, 0, 0, 1), test.inspect(2 ^ 24))
test.compare(test.newBuffer(FLOAT, 0, 0, 128, 59), test.inspect(2 ^ -8))
test.compare(
	test.newBuffer(DOUBLE, 0, 0, 0, 0, 0, 0, 240, 47),
	test.inspect(2 ^ -256)
)
test.compare(test.newBuffer(NAN), test.inspect(0 / 0))

-- error checks
local numDeserialize = require("../src/number").deserialize
test.compare(false, pcall(numDeserialize, test.newBuffer(0), 0)) -- failure to parse

return {}
