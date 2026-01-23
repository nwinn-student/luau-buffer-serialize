--!strict
--[[
	DO NOT RUN THESE TESTS IN PRODUCTION
	
	These tests modify constants, which could 
	cause overwrites or cause serialized data to 
	become unrecognizable by later deserializers.
	
	There are no solutions as the tests could be run 
	in parallel w/ some other task.

	To run:
	luau test
]]

require("@self/nil")
require("@self/boolean")
require("@self/buffer")
require("@self/string")
require("@self/number")
require("@self/vector")
require("@self/table")
require("@self/userdata")

require("@self/link")

local test = require("@self/test")

local serialize = require("./src").serialize
local deserialize = require("./src").deserialize
local pair = require("./src").pair

local inflate = require("./src/inflate")

local proxyTable = {
	newproxy(), -- proxy
	newproxy(), -- yxorp
	newproxy(), -- roxyp
}

require("./src/userdata").setReader(
	function(buf: buffer, pos: number): (unknown, number)
		local tablePosition = buffer.readu8(buf, pos)
		local proxy = proxyTable[tablePosition]
		return proxy, pos + 1
	end
)
require("./src/userdata").setWriter(
	function(
		value: unknown,
		buf: buffer,
		pos: number,
		size: number
	): (buffer, number, number)
		local tablePosition = table.find(proxyTable, value)
		if tablePosition then
			if pos + 1 > size then
				buf, size = inflate(buf, pos + 1, size)
			end
			buffer.writeu8(buf, pos, tablePosition)
			return buf, pos + 1, size
		end

		return buf, pos, size
	end
)

local proxy = proxyTable[1]
local yxorp = proxyTable[2]
local roxyp = proxyTable[3]

pair(1, "value")
pair(64, "eulav")
pair(1343, "lueva")
pair(1, 5)
pair(32, 25)
pair(1055, 125)
pair(1, vector.create(1, 2))
pair(32, vector.create(3, 4))
pair(1055, vector.create(5, 6))
pair(1, proxy)
pair(10, yxorp)
pair(521, roxyp)

local Sir_String = serialize({ "value", "eulav", "lueva" })
local Sir_Number = serialize({ 5, 25, 125 })
local Sir_Vector =
	serialize({ vector.create(1, 2), vector.create(3, 4), vector.create(5, 6) })
local Sir_User = serialize({ proxy, yxorp, roxyp })

-- serialize
test.serial(
	Sir_String,
	test.newBuffer("\197\28\17value\91\17eulav\96\255\17lueva\200")
)
test.serial(
	Sir_Number,
	test.newBuffer(197, 106, 99, 5, 137, 99, 25, 141, 255, 99, 125, 200)
)
test.serial(
	Sir_Vector,
	test.newBuffer("\197\158\144\1\2\0\189\144\3\4\0\193\255\144\5\6\0\200")
)
test.serial(
	Sir_User,
	test.newBuffer(197, 204, 202, 1, 213, 202, 2, 215, 255, 202, 3, 200)
)

-- deserialize
test.compare("value", deserialize(Sir_String)[1])
test.compare("eulav", deserialize(Sir_String)[2])
test.compare("lueva", deserialize(Sir_String)[3])
test.compare(5, deserialize(Sir_Number)[1])
test.compare(25, deserialize(Sir_Number)[2])
test.compare(125, deserialize(Sir_Number)[3])
test.compare(vector.create(1, 2), deserialize(Sir_Vector)[1])
test.compare(vector.create(3, 4), deserialize(Sir_Vector)[2])
test.compare(vector.create(5, 6), deserialize(Sir_Vector)[3])
test.compare(proxy, deserialize(Sir_User)[1])
test.compare(yxorp, deserialize(Sir_User)[2])
test.compare(roxyp, deserialize(Sir_User)[3])

-- built-ins
test.compare(false, pcall(pair, 5, 0))
test.compare(false, pcall(pair, 5, 1))
test.compare(false, pcall(pair, 5, ""))
test.compare(false, pcall(pair, 5, vector.zero))
test.compare(false, pcall(pair, 5, vector.one))
test.compare(false, pcall(pair, 5, vector.create(0, 0, 1)))
test.compare(false, pcall(pair, 5, vector.create(0, 1)))
test.compare(false, pcall(pair, 5, vector.create(0, 1, 1)))
test.compare(false, pcall(pair, 5, vector.create(1, 0, 0)))
test.compare(false, pcall(pair, 5, vector.create(1, 0, 1)))
test.compare(false, pcall(pair, 5, vector.create(1, 1)))

return {}
