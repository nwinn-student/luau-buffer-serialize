--!strict
-- Runs tests for ../BufferSerializer/userdata

local test = require("./test")
local proxy = newproxy()

-- Userdata is very special
require("../src/userdata").setWriter(function(value: unknown, buf: buffer, pos: number, size: number): (buffer, number, number)
	
end)
require("../src/userdata").setReader(function(buf: buffer, pos: number): (unknown, number)
	
end)

-- Check that string.luau works properly
local udSerialize = test.newSerializer(proxy)
local udDeserialize = test.newDeserializer(proxy)

local Sir_Proxy = udSerialize(proxy)

-- serialization
test.serial(Sir_Proxy, test.newBuffer(203))

-- deserialization
test.compare(proxy, udDeserialize(Sir_Proxy))


-- Check that init.luau works with userdata.luau properly
local serialize = require("../src").serialize
local deserialize = require("../src").deserialize

Sir_Proxy = serialize(proxy)

-- serialization
test.serial(Sir_Proxy, test.newBuffer(203))

-- deserialization
test.compare(proxy, deserialize(Sir_Proxy))

require("../src/userdata").resetRead()
require("../src/userdata").resetWrite()

test.complete("USERDATA")

return {}
