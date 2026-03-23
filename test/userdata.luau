--!strict
-- Runs tests for ../src/userdata

local test = require("./test")
local userdata = require("../src/userdata")

local CUSTOM = 202
local UNSUPPORTED = 203

local proxy = newproxy()
local zero_proxy = newproxy()

-- Check that userdata.luau works properly
test.compare(test.newBuffer(UNSUPPORTED), test.inspect(userdata.unsupported))

local function reader(buf: buffer, pos: number): (unknown, number)
	local id = buffer.readu8(buf, pos)
	if id == 0 then
		return zero_proxy, pos + 1
	end
	return nil, pos + 1
end

local function writer(
	value: unknown,
	buf: buffer,
	pos: number,
	size: number
): (buffer, number, number)
	if value ~= zero_proxy then
		return buf, pos, size
	end
	buffer.writeu8(buf, pos, 0)
	return buf, pos + 1, size
end
userdata.addSupport({
	serialize = writer,
	deserialize = reader,
})

local obtainedBuffer, obtainedValue = test.inspect(proxy, {
	disableValueComparison = true,
})
test.compare(test.newBuffer(UNSUPPORTED), obtainedBuffer)
test.compare(userdata.unsupported, obtainedValue)

test.compare(test.newBuffer(CUSTOM, 0), test.inspect(zero_proxy))

return {}
