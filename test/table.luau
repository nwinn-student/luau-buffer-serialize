--!strict
-- Runs tests for ../src/table

local bs = require("@BufferSerializer")
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

local fullExisting = {}
for i = 1, 65535 do
	fullExisting[i] = string.format("%-5i", i) -- force entry into existing
end
fullExisting[65536] = fullExisting
for i = 65536, 65535 + 65536 do
	fullExisting[i] = fullExisting[i - 65535]
end

local overflowExisting = {}
for i = 1, 65536 do
	overflowExisting[i] = string.format("%-5i", i) -- force entry into existing
end
overflowExisting[65537] = overflowExisting[61440]

local overflowExistingUnder = {}
for i = 1, 65536 do
	overflowExistingUnder[i] = string.format("%-5i", i) -- force entry into existing
end
overflowExistingUnder[65537] = overflowExistingUnder[61439]

local overflowExistingOver = {}
for i = 1, 65536 do
	overflowExistingOver[i] = string.format("%-5i", i) -- force entry into existing
end
overflowExistingOver[65537] = overflowExistingOver[61441]

local doubleFullExisting = {}
for i = 1, 65535 do
	doubleFullExisting[i] = string.format("%-5i", i) -- force entry into existing
end
doubleFullExisting[65536] = doubleFullExisting
for i = 65536, 65536 + 65535 do
	doubleFullExisting[i] = doubleFullExisting[i - 65536]
end
for i = 65536 + 65535, 65536 + 65535 + 4096 do
	doubleFullExisting[i] = string.format("%-5i", i - 65535)
end
for i = 65536 + 65535 + 4096, 65536 + 65535 + 4096 + 4096 do
	doubleFullExisting[i] = doubleFullExisting[i - 4096]
end

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

-- flaws cause output to be flooded
local fullExistingBuffer = bs.serialize(fullExisting)
test.compare(fullExisting, bs.deserialize(fullExistingBuffer))
test.compare(
	EXIST,
	buffer.readu8(fullExistingBuffer, buffer.len(fullExistingBuffer) - 4)
)
local overflowExistingBuffer = bs.serialize(overflowExisting)
test.compare(overflowExisting, bs.deserialize(overflowExistingBuffer))
test.compare(
	17, -- string 5, fails to save this as existing
	buffer.readu8(overflowExistingBuffer, buffer.len(overflowExistingBuffer) - 7)
)
local overflowExistingUnderBuffer = bs.serialize(overflowExistingUnder)
test.compare(overflowExistingUnder, bs.deserialize(overflowExistingUnderBuffer))
test.compare(
	EXIST,
	buffer.readu8(
		overflowExistingUnderBuffer,
		buffer.len(overflowExistingUnderBuffer) - 4
	)
)
local overflowExistingOverBuffer = bs.serialize(overflowExistingOver)
test.compare(overflowExistingOver, bs.deserialize(overflowExistingOverBuffer))
test.compare(
	EXIST,
	buffer.readu8(
		overflowExistingOverBuffer,
		buffer.len(overflowExistingOverBuffer) - 4
	)
)

test.compare(doubleFullExisting, bs.deserialize(bs.serialize(doubleFullExisting)))

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
