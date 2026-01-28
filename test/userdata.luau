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

userdata.addSupport({
	tag = function(data: any)
		return 0
	end,
	serialize = function()
		return false
	end,
	deserialize = function(data, tag)
		test.compare(data, false)
		test.compare(tag, 0)
		return proxy
	end,
})

local Sir_Custom = serialize(proxy)

-- serialization
test.serial(Sir_Custom, test.newBuffer(CUSTOM, 0, 2))

-- deserialization
test.compare(proxy, deserialize(Sir_Custom))

userdata.clearSupport()

return {}
