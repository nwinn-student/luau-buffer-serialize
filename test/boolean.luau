--!strict
-- Runs tests for ../src/boolean

local test = require("./test")
local TRUE = 1
local FALSE = 2

-- Check that boolean.luau works properly
test.compare(test.newBuffer(TRUE), test.inspect(true))
test.compare(test.newBuffer(FALSE), test.inspect(false))

return {}
