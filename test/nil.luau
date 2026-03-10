--!strict
-- Runs tests for ../src/nil

local test = require("./test")
local NIL = 0

-- Check that nil.luau works properly
test.compare(test.newBuffer(NIL), test.inspect(nil))

return {}
