--!strict
-- Runs tests for ../BufferSerializer/buffer

local test = require("./test")

-- Check that buffer.luau works properly
local serialize = require("../src").serialize
local deserialize = require("../src").deserialize

local Sir_Empty = serialize(test.sizedBuffer(0))
local Sir_Byte = serialize(test.sizedBuffer(2^0))
local Sir_Char = serialize(test.sizedBuffer(2^8))
local Sir_Tryte = serialize(test.sizedBuffer(2^16))
local Sir_Int = serialize(test.sizedBuffer(2^24))

-- serialization
test.compare(Sir_Empty, test.newBuffer(3))
test.compare(Sir_Byte, test.sizedBuffer(3, 4, 1))
test.compare(Sir_Char, test.sizedBuffer(259, 5, 0, 1))
test.compare(Sir_Tryte, test.sizedBuffer(65540, 6, 0, 0, 1))
test.compare(Sir_Int, test.sizedBuffer(16777221, 7, 0, 0, 0, 1))

-- deserialization
test.compare(test.newBuffer(), deserialize(Sir_Empty))
test.compare(test.sizedBuffer(2^0), deserialize(Sir_Byte))
test.compare(test.sizedBuffer(2^8), deserialize(Sir_Char))
test.compare(test.sizedBuffer(2^16), deserialize(Sir_Tryte))
test.compare(test.sizedBuffer(2^24), deserialize(Sir_Int))

test.complete("BUFFER")

return {}
