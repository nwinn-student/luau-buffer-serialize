--!strict
-- Runs tests for ../src/nil

local test = require("./test")
local NIL = 0

-- Check that nil.luau works properly
local serialize = require("../src").serialize
local deserialize = require("../src").deserialize

local Sir_Nil = serialize(nil)

test.compare(nil, deserialize(Sir_Nil))
test.serial(Sir_Nil, test.newBuffer(NIL))

return {}
