--!strict
-- Runs tests for ../BufferSerializer/string

local test = require("./test")

-- Check that string.luau works properly
local strSerialize = require("../src/string").serialize
local strDeserialize = require("../src/string").deserialize

local Sir_Empty = strSerialize("", buffer.create(1), 0, 1)
local Sir_Byte = strSerialize(string.rep("\0", 2^5), buffer.create(1), 0, 1)
local Sir_Char = strSerialize(string.rep("\0", 2^8), buffer.create(1), 0, 1)
local Sir_Tryte = strSerialize(string.rep("\0", 2^16), buffer.create(1), 0, 1)
local Sir_Int = strSerialize(string.rep("\0", 2^24), buffer.create(1), 0, 1)

-- serialization
test.serial(Sir_Empty, test.newBuffer(9))
test.serial(Sir_Byte, test.sizedBuffer(64, 10, 32))
test.serial(Sir_Char, test.sizedBuffer(512, 11, 0, 1))
test.serial(Sir_Tryte, test.sizedBuffer(131072, 12, 0, 0, 1))
test.serial(Sir_Int, test.sizedBuffer(33554432, 13, 0, 0, 0, 1))

-- deserialization
test.compare("", strDeserialize(Sir_Empty, 0))
test.compare(string.rep("\0", 2^5), strDeserialize(Sir_Byte, 0))
test.compare(string.rep("\0", 2^8), strDeserialize(Sir_Char, 0))
test.compare(string.rep("\0", 2^16), strDeserialize(Sir_Tryte, 0))
test.compare(string.rep("\0", 2^24), strDeserialize(Sir_Int, 0))


-- Check that init.luau works with string.luau properly
local serialize = require("../src").serialize
local deserialize = require("../src").deserialize

Sir_Empty = serialize("")
Sir_Byte = serialize(string.rep("\0", 2^5))
Sir_Char = serialize(string.rep("\0", 2^8))
Sir_Tryte = serialize(string.rep("\0", 2^16))
Sir_Int = serialize(string.rep("\0", 2^24))

-- serialization
test.serial(Sir_Empty, test.newBuffer(9))
test.serial(Sir_Byte, test.sizedBuffer(34, 10, 32))
test.serial(Sir_Char, test.sizedBuffer(259, 11, 0, 1))
test.serial(Sir_Tryte, test.sizedBuffer(65540, 12, 0, 0, 1))
test.serial(Sir_Int, test.sizedBuffer(16777221, 13, 0, 0, 0, 1))

-- deserialization
test.compare("", deserialize(Sir_Empty))
test.compare(string.rep("\0", 2^5), deserialize(Sir_Byte))
test.compare(string.rep("\0", 2^8), deserialize(Sir_Char))
test.compare(string.rep("\0", 2^16), deserialize(Sir_Tryte))
test.compare(string.rep("\0", 2^24), deserialize(Sir_Int))

test.complete("STRING")

return {}
