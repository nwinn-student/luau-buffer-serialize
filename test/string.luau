--!strict
-- Runs tests for ../src/string

local test = require("./test")
local EMPTY = 8
local BYTE = 9
local CHAR = 10
local TRYTE = 11
local INT = 12

-- Check that string.luau works properly
local serialize = require("../src").serialize
local deserialize = require("../src").deserialize

local Sir_Empty = serialize("")
local Sir_Byte = serialize(string.rep("\0", 2 ^ 5))
local Sir_Char = serialize(string.rep("\0", 2 ^ 8))
local Sir_Tryte = serialize(string.rep("\0", 2 ^ 16))
local Sir_Int = serialize(string.rep("\0", 2 ^ 24))

-- serialization
test.serial(Sir_Empty, test.newBuffer(EMPTY))
test.serial(Sir_Byte, test.sizedBuffer(34, BYTE, 32))
test.serial(Sir_Char, test.sizedBuffer(259, CHAR, 0, 1))
test.serial(Sir_Tryte, test.sizedBuffer(65540, TRYTE, 0, 0, 1))
test.serial(Sir_Int, test.sizedBuffer(16777221, INT, 0, 0, 0, 1))

-- deserialization
test.compare("", deserialize(Sir_Empty))
test.compare(string.rep("\0", 2 ^ 5), deserialize(Sir_Byte))
test.compare(string.rep("\0", 2 ^ 8), deserialize(Sir_Char))
test.compare(string.rep("\0", 2 ^ 16), deserialize(Sir_Tryte))
test.compare(string.rep("\0", 2 ^ 24), deserialize(Sir_Int))

-- error checks
local strDeserialize = require("../src/string").deserialize
test.compare(false, pcall(strDeserialize, test.newBuffer(0), 0)) -- failure to parse

return {}
