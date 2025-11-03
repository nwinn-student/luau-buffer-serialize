--!strict
-- Runs tests for ../src/boolean

local test = require("./test")
local TRUE = 1
local FALSE = 2

-- Check that boolean.luau works properly
local serialize = require("../src").serialize
local deserialize = require("../src").deserialize

local True_Bool = serialize(true)
local False_Bool = serialize(false)

test.compare(true, deserialize(True_Bool))
test.serial(True_Bool, test.newBuffer(TRUE))

test.compare(false, deserialize(False_Bool))
test.serial(False_Bool, test.newBuffer(FALSE))

return {}
