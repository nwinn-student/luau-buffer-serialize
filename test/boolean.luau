--!strict
-- Runs tests for ../BufferSerializer/boolean

local test = require("./test")


-- Check that boolean.luau works properly
local booleanSerialize = test.newSerializer(false)
local booleanDeserialize = test.newDeserializer(false)

local True_Bool = booleanSerialize(true)
local False_Bool = booleanSerialize(false)

test.compare(true, booleanDeserialize(True_Bool))
test.serial(True_Bool, test.newBuffer(1))

test.compare(false, booleanDeserialize(False_Bool))
test.serial(False_Bool, test.newBuffer(2))


-- Check that init.luau works with buffer.luau properly
local serialize = require("../src").serialize
local deserialize = require("../src").deserialize

True_Bool = serialize(true)
False_Bool = serialize(false)

test.compare(true, deserialize(True_Bool))
test.serial(True_Bool, test.newBuffer(1))

test.compare(false, deserialize(False_Bool))
test.serial(False_Bool, test.newBuffer(2))

test.complete("BOOLEAN")

return {}
