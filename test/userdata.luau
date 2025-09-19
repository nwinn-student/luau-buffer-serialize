--!strict
-- Runs tests for ../BufferSerializer/userdata

local test = require("./test")
local proxy = newproxy()

-- Check that userdata.luau works properly
local udSerialize = test.newSerializer(proxy)
local udDeserialize = test.newDeserializer(proxy)

local Sir_Proxy = udSerialize(proxy)

-- serialization
test.serial(Sir_Proxy, test.newBuffer(203))

-- deserialization
test.compare("userdata", type(udDeserialize(Sir_Proxy)))


-- Check that init.luau works with userdata.luau properly
local serialize = require("../src").serialize
local deserialize = require("../src").deserialize

Sir_Proxy = serialize(proxy)

-- serialization
test.serial(Sir_Proxy, test.newBuffer(203))

-- deserialization
test.compare("userdata", type(deserialize(Sir_Proxy)))

-- constants [show risks]
local function ds(v: any): any 
	return deserialize(serialize(v))
end

local pair = require("../src").pair

local One = newproxy()
local Two = newproxy()
local Three = newproxy()
local Four = newproxy()
local Five = newproxy()
local Six = newproxy()
local Seven = newproxy()

-- Regular tests
pair(8, One)
pair(16, Two)
pair(128, Three)
pair(1039, Four)

test.serial(serialize(One), test.newBuffer(211))
test.serial(serialize(Two), test.newBuffer(219))
test.serial(serialize(Three), test.newBuffer(220, 112))
test.serial(serialize(Four), test.newBuffer(223, 255))

test.compare(One, ds(One))
test.compare(Two, ds(Two))
test.compare(Three, ds(Three))
test.compare(Four, ds(Four))

-- Serializes multiple values to the same id
--	To show that the latest is used
pair(1, Five)
pair(1, Six)

test.serial(serialize(Five), test.newBuffer(203))
test.compare("userdata", type(ds(Five))) -- it will be unspecified newproxy

test.serial(serialize(Six), test.newBuffer(204))
test.compare(Six, ds(Six))

-- Serializes the same value to multiple ids
--	To show that the lastest is used
pair(33, One) -- 32 -> 33

test.serial(serialize(One), test.newBuffer(220, 17))
test.compare(One, ds(One))

-- Attempts to deserialize an invalid constant
--	50 is an previously valid string constant
--	Simulates migration from a value from 1 id to another
--		but failure to account for backwards compatibility
test.compare(nil, deserialize(test.newBuffer(50)))

-- Attempts to deserialize a value from before it was made a constant
local Sir_Seven = serialize(Seven)
pair(7, Seven)
test.compare("userdata", type(deserialize(Sir_Seven))) -- nothing changes

require("../src/userdata").resetRead()
require("../src/userdata").resetWrite()

-- Custom reader/writer functions will be dealt w/ later
--[[
	Since the functions are not user-specified, 
		but usually extender specified, we can 
		be much more lax w/ the restrictions.
]]

test.complete("USERDATA")

return {}
