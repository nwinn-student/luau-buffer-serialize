--!strict
-- Runs tests for ../BufferSerializer/nil

local test = require("./test")

-- Check that nil.luau works properly
local serialize = require("../src").serialize
local deserialize = require("../src").deserialize

local Sir_Nil = serialize(nil)

test.compare(nil, deserialize(Sir_Nil))
test.serial(Sir_Nil, test.newBuffer(0))

test.complete("NIL")

return {}
