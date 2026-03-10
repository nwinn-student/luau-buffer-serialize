--!strict
-- Runs tests for ../src/table

local test = require("./test")

local ZERO = 97
local ONE = 98

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
test.compare(test.newBuffer(EMPTY), test.inspect({}))
test.compare(
	test.newBuffer(TABLE, ONE, ARRAYEND, ZERO, ONE, TABLEEND),
	test.inspect({ [0] = 1, 1 })
)
test.compare(test.newBuffer(ARRAY, ONE, TABLEEND), test.inspect({ 1 }))
test.compare(test.newBuffer(DICT, ZERO, ONE, TABLEEND), test.inspect({ [0] = 1 }))
test.compare(
	test.newBuffer(ARRAY, 15, "bbb", EXIST, 1, 0, TABLEEND),
	test.inspect({ "bbb", "bbb" })
)
test.compare(test.newBuffer(ARRAY, EXIST, 0, 0, TABLEEND), test.inspect(recurse))

local serialize = require("../src").serialize
local deserialize = require("../src").deserialize

-- pairs
local pair = require("../src").pair
local calcId = require("../src/link").calculateId

pair(5, "aaa")

local aaaId = calcId(5, "string")

local Sir_Paired = serialize({ "aaa" })
local Sir_DuoPaired = serialize({ "aaa", "aaa" })

-- serialization
test.serial(Sir_Paired, test.newBuffer(ARRAY, aaaId, 15, "aaa", TABLEEND))
test.serial(
	Sir_DuoPaired,
	test.newBuffer(ARRAY, aaaId, 15, "aaa", aaaId, TABLEEND)
)

-- deserialization
test.compare({ "aaa" }, deserialize(Sir_Paired))
test.compare({ "aaa", "aaa" }, deserialize(Sir_DuoPaired))

-- error check
local tabDeserialize = require("../src/table").deserialize
test.compare(false, pcall(tabDeserialize, test.newBuffer(0), 0)) -- failure to parse table
test.compare(
	false,
	pcall(tabDeserialize, test.newBuffer(ARRAY, 15, 98, 98, 98, EXIST, 0, 1), 0)
) -- failure to parse existing
test.compare(false, pcall(tabDeserialize, test.newBuffer(DICT, 1, 0), 0)) -- failure to parse nil in dict
test.compare(false, pcall(tabDeserialize, test.newBuffer(DICT, 1, 232), 0)) -- failure to parse future
test.compare(false, pcall(tabDeserialize, test.newBuffer(DICT, 1, 255), 0)) -- failure to parse extension

return {}
