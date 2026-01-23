--!strict
-- Runs tests for ../src/table

local test = require("./test")
local EMPTY = 194
local TABLE = 195
local EXIST = 196
local ARRAY = 197
local DICT = 198
local ARRAYEND = 199
local TABLEEND = 200

local recurse = {}
recurse[1] = recurse

-- Check that table.luau works properly
local serialize = require("../src").serialize
local deserialize = require("../src").deserialize

local Sir_Empty = serialize({})
local Sir_Table = serialize({ [0] = 1, 1 })
local Sir_Array = serialize({ 1 })
local Sir_Dict = serialize({ [0] = 1 })
local Sir_Exist = serialize({ "bbb", "bbb" })
local Sir_Recurs = serialize(recurse)

-- serialization
test.serial(Sir_Empty, test.newBuffer(EMPTY))
test.serial(Sir_Table, test.newBuffer(TABLE, 89, ARRAYEND, 88, 89, TABLEEND))
test.serial(Sir_Array, test.newBuffer(ARRAY, 89, TABLEEND))
test.serial(Sir_Dict, test.newBuffer(DICT, 88, 89, TABLEEND))
test.serial(
	Sir_Exist,
	test.newBuffer(ARRAY, 10, 3, 98, 98, 98, EXIST, 1, 0, TABLEEND)
)
test.serial(Sir_Recurs, test.newBuffer(ARRAY, EXIST, 0, 0, TABLEEND))

-- deserialization
test.compare({}, deserialize(Sir_Empty))
test.compare({ [0] = 1, 1 }, deserialize(Sir_Table))
test.compare({ 1 }, deserialize(Sir_Array))
test.compare({ [0] = 1 }, deserialize(Sir_Dict))
test.compare({ "bbb", "bbb" }, deserialize(Sir_Exist))
test.compare(recurse, deserialize(Sir_Recurs))

-- pairs
local pair = require("../src").pair
local calcId = require("../src/link").calculateId

pair(5, "aaa")

local aaaId = calcId(5, "string")

local Sir_Paired = serialize({ "aaa" })
local Sir_DuoPaired = serialize({ "aaa", "aaa" })

-- serialization
test.serial(Sir_Paired, test.newBuffer(ARRAY, aaaId, 10, 3, "aaa", TABLEEND))
test.serial(
	Sir_DuoPaired,
	test.newBuffer(ARRAY, aaaId, 10, 3, "aaa", aaaId, TABLEEND)
)

-- deserialization
test.compare({ "aaa" }, deserialize(Sir_Paired))
test.compare({ "aaa", "aaa" }, deserialize(Sir_DuoPaired))

-- error check
local tabDeserialize = require("../src/table").deserialize
test.compare(false, pcall(tabDeserialize, test.newBuffer(0), 0)) -- failure to parse table
test.compare(
	false,
	pcall(
		tabDeserialize,
		test.newBuffer(ARRAY, 10, 3, 98, 98, 98, EXIST, 0, 1),
		0
	)
) -- failure to parse existing
test.compare(false, pcall(tabDeserialize, test.newBuffer(DICT, 1, 0), 0)) -- failure to parse nil in dict
test.compare(false, pcall(tabDeserialize, test.newBuffer(DICT, 1, 232), 0)) -- failure to parse future
test.compare(false, pcall(tabDeserialize, test.newBuffer(DICT, 1, 255), 0)) -- failure to parse extension

return {}
