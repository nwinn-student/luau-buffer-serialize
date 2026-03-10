--!strict
-- Runs tests for ../src/userdata

local inflate = require("../src/inflate")
local test = require("./test")
local userdata = require("../src/userdata")

local CUSTOM = 202
local NIL = 203

local proxy = newproxy()
local zero_proxy = newproxy()

-- Check that userdata.luau works properly
-- TODO: Make this userdata.unsupported instead of proxy
-- Currently intentional that it fails
test.compare(test.newBuffer(NIL), test.inspect(proxy))

-- By default (currently) the reader and writer are initialized to nil
test.compare(nil, userdata.getReader())
test.compare(nil, userdata.getWriter())
test.compare(false, pcall(userdata.setReader, nil :: any))
test.compare(false, pcall(userdata.setWriter, nil :: any))

local function reader(buf: buffer, pos: number): (unknown, number)
	-- TODO: Remove this later
	--
	if buffer.readu8(buf, pos) == NIL then
		return proxy, pos + 1
	end
	--

	return zero_proxy, pos + 1 -- proxy should not get here
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
	buf, size = inflate(buf, pos + 1, size)
	buffer.writeu8(buf, pos, 0)
	return buf, pos + 1, size
end
userdata.setReader(reader)
userdata.setWriter(writer)

test.compare(reader, userdata.getReader())
test.compare(writer, userdata.getWriter())

-- TODO: Reflect this test in the code once it is NIL
test.compare(test.newBuffer(CUSTOM, NIL), test.inspect(proxy)) -- currently CUSTOM NIL, but should become just NIL
test.compare(test.newBuffer(CUSTOM, 0), test.inspect(zero_proxy))

return {}
