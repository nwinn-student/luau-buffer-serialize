--!strict
-- Runs tests for ../src/userdata

local test = require("./test")

local CUSTOM = 202
local NIL = 203
local EMPTY_TABLE = 194
local ARRAY = 197
local TABLE_END = 200

local proxy = newproxy()
local empty_usertable = newproxy()
local usertable = newproxy()

-- Check that userdata.luau works properly
local serialize = require("../src").serialize
local deserialize = require("../src").deserialize

local tabSerialize = require("../src/table").serialize
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
	else -- if id == ARRAY then
		test.serial(buf, test.newBuffer(CUSTOM, ARRAY, 1, TABLE_END))
		test.compare(1, pos)
		local tab
		tab, pos = tabDeserialize(buf, pos)
		test.compare(true, tab[1])
		test.compare(5, pos)
		return usertable, pos
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
	else -- if value == usertable then
		test.compare(value, usertable)
		test.serial(buf, test.newBuffer(CUSTOM))
		test.compare(1, pos)
		test.compare(1, size)
		buf, pos, size = tabSerialize({ true }, buf, pos, size)
		test.serial(buf, test.newBuffer(CUSTOM, ARRAY, 1, TABLE_END))
		test.compare(4, pos)
		test.compare(4, size)
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

-- serialization
test.serial(Sir_Custom, test.newBuffer(CUSTOM, NIL)) -- This isn't intentional?
test.serial(Sir_EmptyUserTable, test.newBuffer(CUSTOM, EMPTY_TABLE))
test.serial(Sir_UserTable, test.newBuffer(CUSTOM, ARRAY, 1, TABLE_END))

-- deserialization
test.compare(proxy, deserialize(Sir_Custom))
test.compare(empty_usertable, deserialize(Sir_EmptyUserTable))
test.compare(usertable, deserialize(Sir_UserTable))

return {}
