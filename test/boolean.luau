--!strict
-- Runs tests for ../BufferSerializer/boolean

local test = require("./test")

-- Check that boolean.luau works properly
local serialize = require("../src").serialize
local deserialize = require("../src").deserialize

local True_Bool = serialize(true)
local False_Bool = serialize(false)

test.compare(true, deserialize(True_Bool))
test.serial(True_Bool, test.newBuffer(1))

test.compare(false, deserialize(False_Bool))
test.serial(False_Bool, test.newBuffer(2))

test.complete("BOOLEAN")

return {}
