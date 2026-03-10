--!strict
-- Runs tests for ../src/string

local test = require("./test")
local EMPTY = 8
local BYTE = 9
local CHAR = 10
local TRYTE = 11
local INT = 12
local ONE = 13
local FIFTEEN = 27

-- Check that string.luau works properly
test.compare(test.newBuffer(EMPTY), test.inspect(""))
test.compare(
	test.sizedBuffer(34, BYTE, 32),
	test.inspect(string.rep("\0", 2 ^ 5))
)
test.compare(
	test.sizedBuffer(259, CHAR, 0, 1),
	test.inspect(string.rep("\0", 2 ^ 8))
)
test.compare(
	test.sizedBuffer(65540, TRYTE, 0, 0, 1),
	test.inspect(string.rep("\0", 2 ^ 16))
)
test.compare(
	test.sizedBuffer(16777221, INT, 0, 0, 0, 1),
	test.inspect(string.rep("\0", 2 ^ 24))
)
test.compare(test.sizedBuffer(2, ONE), test.inspect("\0"))
test.compare(test.sizedBuffer(16, FIFTEEN), test.inspect(string.rep("\0", 15)))

-- error checks
local strDeserialize = require("../src/string").deserialize
test.compare(false, pcall(strDeserialize, test.newBuffer(0), 0)) -- failure to parse

return {}
