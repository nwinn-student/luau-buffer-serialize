--!strict
-- Runs tests for ../BufferSerializer/userdata

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

-- Custom reader/writer functions will be dealt w/ later
--[[
	Since the functions are not user-specified, 
		but usually extender specified, we can 
		be much more lax w/ the restrictions.
]]
local userdata = require("../src/userdata")
userdata.setReader(function(buf: buffer, pos: number): (unknown, number)
	print(buf, pos)
	return buf, pos
end)
userdata.setWriter(
	function(
		value: unknown,
		buf: buffer,
		pos: number,
		size: number
	): (buffer, number, number)
		print(value, buf, pos, size)
		return buf, pos, size
	end
)

local Sir_Custom = serialize(proxy)

-- serialization (?! why does it do this?)
test.serial(Sir_Custom, test.newBuffer(CUSTOM, NIL))

-- deserialization
test.compare("userdata", type(deserialize(Sir_Custom)))

return {}
