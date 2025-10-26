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

return {}
