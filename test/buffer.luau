--!strict
-- Runs tests for ../src/buffer

local test = require("./test")
local EMPTY = 3
local BYTE = 4
local CHAR = 5
local TRYTE = 6
local INT = 7

-- Check that buffer.luau works properly
test.compare(test.newBuffer(EMPTY), test.inspect(test.newBuffer()))
test.compare(test.sizedBuffer(3, BYTE, 1), test.inspect(test.sizedBuffer(2 ^ 0)))
test.compare(
	test.sizedBuffer(259, CHAR, 0, 1),
	test.inspect(test.sizedBuffer(2 ^ 8))
)
test.compare(
	test.sizedBuffer(65540, TRYTE, 0, 0, 1),
	test.inspect(test.sizedBuffer(2 ^ 16))
)
test.compare(
	test.sizedBuffer(16777221, INT, 0, 0, 0, 1),
	test.inspect(test.sizedBuffer(2 ^ 24))
)

-- error checks
local bufDeserialize = require("../src/buffer").deserialize
test.compare(false, pcall(bufDeserialize, test.newBuffer(0), 0)) -- failure to parse

return {}
