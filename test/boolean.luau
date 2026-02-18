--!strict
-- Runs tests for ../src/boolean

local test = require("./test")
local TRUE = 1
local FALSE = 2

-- Check that boolean.luau works properly
local serialize = require("../src/boolean").serialize
local deserialize = require("../src/boolean").deserialize

local True_Bool, pos_t, size_t =
	serialize(true, test.newBuffer(100, 0, 200), 1, 3)
local False_Bool, pos_f, size_f =
	serialize(false, test.newBuffer(100, 0, 200), 1, 3)

local True, dpos_t = deserialize(True_Bool, 1)
local False, dpos_f = deserialize(False_Bool, 1)

-- serialize
test.serial(True_Bool, test.newBuffer(100, TRUE, 200))
test.compare(2, pos_t)
test.compare(3, size_t)
test.serial(False_Bool, test.newBuffer(100, FALSE, 200))
test.compare(2, pos_f)
test.compare(3, size_f)

-- deserialize
test.compare(true, True)
test.compare(dpos_t, 2)
test.compare(false, False)
test.compare(dpos_f, 2)

return {}
