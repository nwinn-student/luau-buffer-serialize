--!strict
-- Runs tests for ../BufferSerializer/buffer

local test = require("./test")

-- Check that nil.luau works properly (we are not trimming!)
local bufSerialize = require("../src/buffer").serialize
local bufDeserialize = require("../src/buffer").deserialize

local Sir_Empty = bufSerialize(test.sizedBuffer(0), test.sizedBuffer(1), 0, 1)
local Sir_Byte = bufSerialize(test.sizedBuffer(2^0), test.sizedBuffer(1), 0, 1)
local Sir_Char = bufSerialize(test.sizedBuffer(2^8), test.sizedBuffer(1), 0, 1)
local Sir_Tryte = bufSerialize(test.sizedBuffer(2^16), test.sizedBuffer(1), 0, 1)
local Sir_Int = bufSerialize(test.sizedBuffer(2^24), test.sizedBuffer(1), 0, 1)

-- serialization
test.compare(Sir_Empty, test.newBuffer(3))
test.compare(Sir_Byte, test.sizedBuffer(4, 4, 1))
test.compare(Sir_Char, test.sizedBuffer(512, 5, 0, 1))
test.compare(Sir_Tryte, test.sizedBuffer(131072, 6, 0, 0, 1))
test.compare(Sir_Int, test.sizedBuffer(33554432, 7, 0, 0, 0, 1))

-- deserialization
test.compare(test.newBuffer(), bufDeserialize(Sir_Empty, 0))
test.compare(test.sizedBuffer(2^0), bufDeserialize(Sir_Byte, 0))
test.compare(test.sizedBuffer(2^8), bufDeserialize(Sir_Char, 0))
test.compare(test.sizedBuffer(2^16), bufDeserialize(Sir_Tryte, 0))
test.compare(test.sizedBuffer(2^24), bufDeserialize(Sir_Int, 0))


-- Check that init.luau works with buffer.luau properly
local serialize = require("../src").serialize
local deserialize = require("../src").deserialize

Sir_Empty = serialize(test.sizedBuffer(0))
Sir_Byte = serialize(test.sizedBuffer(2^0))
Sir_Char = serialize(test.sizedBuffer(2^8))
Sir_Tryte = serialize(test.sizedBuffer(2^16))
Sir_Int = serialize(test.sizedBuffer(2^24))

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
