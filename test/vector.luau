--!strict
-- Runs tests for ../BufferSerializer/vector

local test = require("./test")

-- Check that vector.luau works properly
local vecSerialize = require("../src/vector").serialize
local vecDeserialize = require("../src/vector").deserialize

local Sir_Zero = vecSerialize(vector.zero, buffer.create(1), 0, 1)
local Sir_One = vecSerialize(vector.one, buffer.create(1), 0, 1)
local Sir_X = vecSerialize(vector.zero, buffer.create(1), 0, 1)
local Sir_Y = vecSerialize(vector.zero, buffer.create(1), 0, 1)
local Sir_Z = vecSerialize(vector.zero, buffer.create(1), 0, 1)
local Sir_XY = vecSerialize(vector.zero, buffer.create(1), 0, 1)
local Sir_XZ = vecSerialize(vector.zero, buffer.create(1), 0, 1)
local Sir_YZ = vecSerialize(vector.zero, buffer.create(1), 0, 1)
local Sir_Byte = vecSerialize(vector.zero, buffer.create(1), 0, 1)
local Sir_Char = vecSerialize(vector.zero, buffer.create(1), 0, 1)
local Sir_Tryte = vecSerialize(vector.zero, buffer.create(1), 0, 1)
local Sir_Float = vecSerialize(vector.zero, buffer.create(1), 0, 1)
local Sir_Number = vecSerialize(vector.zero, buffer.create(1), 0, 1)
local Sir_Scalar = vecSerialize(vector.zero, buffer.create(1), 0, 1)

-- serialization
--test.compare(nil, nilDeserialize(Sir_Nil, 0))
--test.serial(Sir_Nil, test.newBuffer(0))


-- Check that init.luau works with vector.luau properly
local serialize = require("../src").serialize
local deserialize = require("../src").deserialize

--Sir_Nil = serialize(nil)

--test.compare(nil, deserialize(Sir_Nil))
--test.serial(Sir_Nil, test.newBuffer(0))

test.complete("VECTOR")

return {}
