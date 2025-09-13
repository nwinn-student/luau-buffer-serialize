--!strict
-- Runs tests for ../BufferSerializer/boolean

local test = require("./test")


-- Check that boolean.luau works properly
local booleanSerialize = require("../src/boolean").serialize
local booleanDeserialize = require("../src/boolean").deserialize

local True_Bool = booleanSerialize(true, buffer.create(1), 0, 1)
local False_Bool = booleanSerialize(false, buffer.create(1), 0, 1)

test.deserial(true, booleanDeserialize(True_Bool, 0))
test.serial(True_Bool, test.newBuffer(1))

test.deserial(false, booleanDeserialize(False_Bool, 0))
test.serial(False_Bool, test.newBuffer(2))


-- Check that init.luau works with buffer.luau properly
local serialize = require("../src").serialize
local deserialize = require("../src").deserialize

True_Bool = serialize(true)
False_Bool = serialize(false)

test.deserial(true, deserialize(True_Bool))
test.serial(True_Bool, test.newBuffer(1))

test.deserial(false, deserialize(False_Bool))
test.serial(False_Bool, test.newBuffer(2))

test.complete("BOOLEAN")

return {}
