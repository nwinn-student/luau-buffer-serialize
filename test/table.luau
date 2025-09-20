--!strict
-- Runs tests for ../BufferSerializer/nil

local test = require("./test")
local recurse = {}
recurse[1] = recurse

-- Check that table.luau works properly
local serialize = require("../src").serialize
local deserialize = require("../src").deserialize

local Sir_Empty = serialize({})
local Sir_Empty = serialize({})
local Sir_Table = serialize({[0] = 1, 1})
local Sir_Array = serialize({1})
local Sir_Dict = serialize({[0] = 1})
local Sir_Exist = serialize({"aaa","aaa"})
local Sir_Recurs = serialize(recurse)

-- serialization
test.serial(Sir_Empty, test.newBuffer(194))
test.serial(Sir_Table, test.newBuffer(195, 89, 199, 88, 89, 200))
test.serial(Sir_Array, test.newBuffer(197, 89, 200))
test.serial(Sir_Dict, test.newBuffer(198, 88, 89, 200))
test.serial(Sir_Exist, test.newBuffer(197, 10, 3, 97, 97, 97, 196, 1, 0, 200))
test.serial(Sir_Recurs, test.newBuffer(197, 196, 0, 0, 200))

-- deserialization
test.compare({}, deserialize(Sir_Empty))
test.compare({[0] = 1, 1}, deserialize(Sir_Table))
test.compare({1}, deserialize(Sir_Array))
test.compare({[0] = 1}, deserialize(Sir_Dict))
test.compare({"aaa","aaa"}, deserialize(Sir_Exist))
--test.compare(recurse, deserialize(Sir_Recurs))


test.complete("TABLE")

return {}
