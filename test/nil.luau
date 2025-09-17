--!strict
-- Runs tests for ../BufferSerializer/nil

local test = require("./test")

-- Check that nil.luau works properly
local nilSerialize = require("../src/nil").serialize
local nilDeserialize = require("../src/nil").deserialize

local Sir_Nil = nilSerialize(nil, buffer.create(1), 0, 1)

test.compare(nil, nilDeserialize(Sir_Nil, 0))
test.serial(Sir_Nil, test.newBuffer(0))


-- Check that init.luau works with nil.luau properly
local serialize = require("../src").serialize
local deserialize = require("../src").deserialize

Sir_Nil = serialize(nil)

test.compare(nil, deserialize(Sir_Nil))
test.serial(Sir_Nil, test.newBuffer(0))

test.complete("NIL")

return {}
