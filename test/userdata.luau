--!strict
-- Runs tests for ../BufferSerializer/userdata

local test = require("./test")
local CUSTOM = 202
local NIL = 203
local CONST_INIT = 203
local CONST_NEXT = 220
local proxy = newproxy()

-- Check that userdata.luau works properly
local serialize = require("../src").serialize
local deserialize = require("../src").deserialize

local Sir_Proxy = serialize(proxy)

-- serialization
test.serial(Sir_Proxy, test.newBuffer(NIL))

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
pair(16 + 112, Three) -- 128
pair(16 + 4*256 - 1, Four) -- 1039

test.serial(serialize(One), test.newBuffer(CONST_INIT + 8))
test.serial(serialize(Two), test.newBuffer(CONST_INIT + 16))
test.serial(serialize(Three), test.newBuffer(CONST_NEXT, 112))
test.serial(serialize(Four), test.newBuffer(CONST_NEXT + 3, 255))

test.compare(One, ds(One))
test.compare(Two, ds(Two))
test.compare(Three, ds(Three))
test.compare(Four, ds(Four))

-- Serializes multiple values to the same id
--	To show that the latest is used
pair(1, Five)
pair(1, Six)

test.serial(serialize(Five), test.newBuffer(NIL))
test.compare("userdata", type(ds(Five))) -- it will be unspecified newproxy

test.serial(serialize(Six), test.newBuffer(CONST_INIT + 1))
test.compare(Six, ds(Six))

-- Serializes the same value to multiple ids
--	To show that the lastest is used
pair(9, One) -- 8 -> 9

test.serial(serialize(One), test.newBuffer(CONST_INIT + 9))
test.compare(One, ds(One))

-- Attempts to deserialize an invalid constant
--	50 is an previously valid string constant
--	Simulates migration from a value from 1 id to another
--		but failure to account for backwards compatibility
test.compare(nil, deserialize(test.newBuffer(CONST_INIT + 8)))

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
