--!strict
-- Runs tests for ../src/userdata

local test = require("./test")
local CUSTOM = 202
local NIL = 203
local proxy = newproxy()

-- Check that userdata.luau works properly
local serialize = require("../src").serialize
local deserialize = require("../src").deserialize

local Sir_Proxy = serialize(proxy)

-- serialization
test.serial(Sir_Proxy, test.newBuffer(NIL))

-- deserialization
test.compare("userdata", type(deserialize(Sir_Proxy)))

-- Custom reader/writer functions
local userdata = require("../src/userdata")
userdata.setReader(function(buf: buffer, pos: number): (unknown, number)
	test.serial(buf, test.newBuffer(202, 203))
	test.compare(pos, 1)
	return proxy, pos
end)
userdata.setWriter(
	function(
		value: unknown,
		buf: buffer,
		pos: number,
		size: number
	): (buffer, number, number)
		test.compare(value, proxy)
		test.serial(buf, test.newBuffer(202))
		test.compare(pos, 1)
		test.compare(size, 1)
		return buf, pos, size
	end
)

local Sir_Custom = serialize(proxy)

-- serialization
test.serial(Sir_Custom, test.newBuffer(CUSTOM, NIL))

-- deserialization
test.compare(proxy, deserialize(Sir_Custom))

return {}
