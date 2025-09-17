--!strict
-- Runs tests for ../BufferSerializer/nil

local test = require("./test")

-- Check that nil.luau works properly
local nilSerialize = test.newSerializer(nil)
local nilDeserialize = test.newDeserializer(nil)

local Sir_Nil = nilSerialize(nil)

test.compare(nil, nilDeserialize(Sir_Nil))
test.serial(Sir_Nil, test.newBuffer(0))


-- Check that init.luau works with nil.luau properly
local serialize = require("../src").serialize
local deserialize = require("../src").deserialize

Sir_Nil = serialize(nil)

test.compare(nil, deserialize(Sir_Nil))
test.serial(Sir_Nil, test.newBuffer(0))

test.complete("NIL")

return {}
