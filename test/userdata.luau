--!strict
-- Runs tests for ../src/userdata

local test = require("./test")

local CUSTOM = 202
local NIL = 203
local ZERO = 97
local EMPTY_TABLE = 194
local ARRAY = 197
local TABLE_END = 200

local proxy = newproxy()
local empty_usertable = newproxy()
local usertable = newproxy()
local multi_usertable = newproxy()

-- Check that userdata.luau works properly
local serialize = require("../src").serialize
local deserialize = require("../src").deserialize

local numSerialize = require("../src/number").serialize
local tabSerialize = require("../src/table").serialize
local numDeserialize = require("../src/number").deserialize
local tabDeserialize = require("../src/table").deserialize

local Sir_Proxy = serialize(proxy)

-- serialization
test.serial(Sir_Proxy, test.newBuffer(NIL))

-- deserialization
test.compare("userdata", type(deserialize(Sir_Proxy)))

-- Custom reader/writer functions
local userdata = require("../src/userdata")

-- By default (currently) the reader and writer are initialized to nil
test.compare(nil, userdata.getReader())
test.compare(nil, userdata.getWriter())
test.compare(false, pcall(userdata.setReader, nil :: any))
test.compare(false, pcall(userdata.setWriter, nil :: any))

local function reader(buf: buffer, pos: number): (unknown, number)
	local id = buffer.readu8(buf, pos)

	if id == NIL then
		test.serial(buf, test.newBuffer(CUSTOM, NIL))
		test.compare(1, pos)
		return proxy, pos + 1
	elseif id == EMPTY_TABLE then
		test.serial(buf, test.newBuffer(CUSTOM, EMPTY_TABLE))
		test.compare(1, pos)
		return empty_usertable, pos + 1
	elseif id == ARRAY then
		test.serial(buf, test.newBuffer(CUSTOM, ARRAY, 1, TABLE_END))
		test.compare(1, pos)
		local tab
		tab, pos = tabDeserialize(buf, pos)
		test.compare(true, tab[1])
		test.compare(4, pos)
		return usertable, pos
	else -- if id == ZERO then
		test.serial(
			buf,
			test.newBuffer(
				CUSTOM,
				ZERO,
				ARRAY,
				1,
				TABLE_END,
				ZERO,
				EMPTY_TABLE,
				ZERO
			)
		)
		test.compare(1, pos)
		local zero1, tab1, zero2, tab2, zero3
		zero1, pos = numDeserialize(buf, pos)
		test.compare(0, zero1)
		test.compare(2, pos)
		tab1, pos = tabDeserialize(buf, pos)
		test.compare({ true }, tab1)
		test.compare(5, pos)
		zero2, pos = numDeserialize(buf, pos)
		test.compare(0, zero2)
		test.compare(6, pos)
		tab2, pos = tabDeserialize(buf, pos)
		test.compare({}, tab2)
		test.compare(7, pos)
		zero3, pos = numDeserialize(buf, pos)
		test.compare(0, zero3)
		test.compare(8, pos)
		-- i want it to error (change table line 551: to have + 1 and line 373 to be 1 for pos)
		return multi_usertable, pos
	end
end

local function writer(
	value: unknown,
	buf: buffer,
	pos: number,
	size: number
): (buffer, number, number)
	if value == proxy then
		test.compare(value, proxy)
		test.serial(buf, test.newBuffer(CUSTOM))
		test.compare(1, pos)
		test.compare(1, size)
		return buf, pos, size
	elseif value == empty_usertable then
		test.compare(value, empty_usertable)
		test.serial(buf, test.newBuffer(CUSTOM))
		test.compare(1, pos)
		test.compare(1, size)
		buf, pos, size = tabSerialize({}, buf, pos, size)
		test.serial(buf, test.newBuffer(CUSTOM, EMPTY_TABLE))
		test.compare(2, pos)
		test.compare(2, size)
		return buf, pos, size
	elseif value == usertable then
		test.compare(value, usertable)
		test.serial(buf, test.newBuffer(CUSTOM))
		test.compare(1, pos)
		test.compare(1, size)
		buf, pos, size = tabSerialize({ true }, buf, pos, size)
		test.serial(buf, test.newBuffer(CUSTOM, ARRAY, 1, TABLE_END))
		test.compare(4, pos)
		test.compare(4, size)
		return buf, pos, size
	else -- if value == multi_usertable then
		test.compare(value, multi_usertable)
		test.serial(buf, test.newBuffer(CUSTOM))
		test.compare(1, pos)
		test.compare(1, size)
		buf, pos, size = numSerialize(0, buf, pos, size)
		test.serial(buf, test.newBuffer(CUSTOM, ZERO))
		test.compare(2, pos)
		test.compare(2, size)
		buf, pos, size = tabSerialize({ true }, buf, pos, size)
		test.serial(buf, test.sizedBuffer(8, CUSTOM, ZERO, ARRAY, 1, TABLE_END))
		test.compare(5, pos)
		test.compare(8, size)
		buf, pos, size = numSerialize(0, buf, pos, size)
		test.serial(
			buf,
			test.sizedBuffer(8, CUSTOM, ZERO, ARRAY, 1, TABLE_END, ZERO)
		)
		test.compare(6, pos)
		test.compare(8, size)
		buf, pos, size = tabSerialize({}, buf, pos, size)
		test.serial(
			buf,
			test.sizedBuffer(
				8,
				CUSTOM,
				ZERO,
				ARRAY,
				1,
				TABLE_END,
				ZERO,
				EMPTY_TABLE
			)
		)
		test.compare(7, pos)
		test.compare(8, size)
		buf, pos, size = numSerialize(0, buf, pos, size)
		test.serial(
			buf,
			test.sizedBuffer(
				8,
				CUSTOM,
				ZERO,
				ARRAY,
				1,
				TABLE_END,
				ZERO,
				EMPTY_TABLE,
				ZERO
			)
		)
		test.compare(8, pos)
		test.compare(8, size)

		return buf, pos, size
	end
end
userdata.setReader(reader)
userdata.setWriter(writer)

test.compare(reader, userdata.getReader())
test.compare(writer, userdata.getWriter())

local Sir_Custom = serialize(proxy)
local Sir_EmptyUserTable = serialize(empty_usertable)
local Sir_UserTable = serialize(usertable)
local Sir_MultiUserTable = serialize(multi_usertable)

-- serialization
test.serial(Sir_Custom, test.newBuffer(CUSTOM, NIL)) -- This isn't intentional?
test.serial(Sir_EmptyUserTable, test.newBuffer(CUSTOM, EMPTY_TABLE))
test.serial(Sir_UserTable, test.newBuffer(CUSTOM, ARRAY, 1, TABLE_END))
test.serial(
	Sir_MultiUserTable,
	test.newBuffer(CUSTOM, ZERO, ARRAY, 1, TABLE_END, ZERO, EMPTY_TABLE, ZERO)
)

-- deserialization
test.compare(proxy, deserialize(Sir_Custom))
test.compare(empty_usertable, deserialize(Sir_EmptyUserTable))
test.compare(usertable, deserialize(Sir_UserTable))
test.compare(multi_usertable, deserialize(Sir_MultiUserTable))

return {}
