--!strict
-- Runs tests for ../BufferSerializer/number

local test = require("./test")

-- Check that number.luau works properly
local numSerialize = require("../src/number").serialize
local numDeserialize = require("../src/number").deserialize

local Sir_Zero = numSerialize(0, buffer.create(1), 0, 1)
local Sir_One = numSerialize(1, buffer.create(1), 0, 1)
local Sir_Byte = numSerialize(2^1, buffer.create(1), 0, 1)
local Sir_Char = numSerialize(2^8, buffer.create(1), 0, 1)
local Sir_Tryte = numSerialize(2^16, buffer.create(1), 0, 1)
local Sir_Int = numSerialize(2^24, buffer.create(1), 0, 1)
local Sir_Float = numSerialize(2^-8, buffer.create(1), 0, 1)
local Sir_Double = numSerialize(2^-256, buffer.create(1), 0, 1)
local Sir_NaN = numSerialize(0/0, buffer.create(1), 0, 1)

-- serialization
test.serial(Sir_Zero, test.newBuffer(88))
test.serial(Sir_One, test.newBuffer(89))
test.serial(Sir_Byte, test.newBuffer(90, 2^1))
test.serial(Sir_Char, test.sizedBuffer(4, 91, 0, 1))
test.serial(Sir_Tryte, test.sizedBuffer(4, 92, 0, 0, 1))
test.serial(Sir_Int, test.sizedBuffer(8, 93, 0, 0, 0, 1))
test.serial(Sir_Float, test.sizedBuffer(8, 94, 0, 0, 128, 59))
test.serial(Sir_Double, test.sizedBuffer(16, 95, 0, 0, 0, 0 ,0, 0, 240, 47))
test.serial(Sir_NaN, test.newBuffer(96))

-- deserialization
test.compare(0, numDeserialize(Sir_Zero, 0))
test.compare(1, numDeserialize(Sir_One, 0))
test.compare(2^1, numDeserialize(Sir_Byte, 0))
test.compare(2^8, numDeserialize(Sir_Char, 0))
test.compare(2^16, numDeserialize(Sir_Tryte, 0))
test.compare(2^24, numDeserialize(Sir_Int, 0))
test.compare(2^-8, numDeserialize(Sir_Float, 0))
test.compare(2^-256, numDeserialize(Sir_Double, 0))
test.compare(0/0, numDeserialize(Sir_NaN, 0))

-- Check that init.luau works with number.luau properly
local serialize = require("../src").serialize
local deserialize = require("../src").deserialize

Sir_Zero = serialize(0)
Sir_One = serialize(1)
Sir_Byte = serialize(2^1)
Sir_Char = serialize(2^8)
Sir_Tryte = serialize(2^16)
Sir_Int = serialize(2^24)
Sir_Float = serialize(2^-8)
Sir_Double = serialize(2^-256)
Sir_NaN = serialize(0/0)

-- serialization
test.serial(Sir_Zero, test.newBuffer(88))
test.serial(Sir_One, test.newBuffer(89))
test.serial(Sir_Byte, test.newBuffer(90, 2^1))
test.serial(Sir_Char, test.newBuffer(91, 0, 1))
test.serial(Sir_Tryte, test.newBuffer(92, 0, 0, 1))
test.serial(Sir_Int, test.newBuffer(93, 0, 0, 0, 1))
test.serial(Sir_Float, test.newBuffer(94, 0, 0, 128, 59))
test.serial(Sir_Double, test.newBuffer(95, 0, 0, 0, 0 ,0, 0, 240, 47))
test.serial(Sir_NaN, test.newBuffer(96))

-- deserialization
test.compare(0, deserialize(Sir_Zero))
test.compare(1, deserialize(Sir_One))
test.compare(2^1, deserialize(Sir_Byte))
test.compare(2^8, deserialize(Sir_Char))
test.compare(2^16, deserialize(Sir_Tryte))
test.compare(2^24, deserialize(Sir_Int))
test.compare(2^-8, deserialize(Sir_Float))
test.compare(2^-256, deserialize(Sir_Double))
test.compare(0/0, deserialize(Sir_NaN))

test.complete("NUMBER")

return {}
