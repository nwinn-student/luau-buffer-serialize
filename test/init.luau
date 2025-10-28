--!strict
--[[
	DO NOT RUN THESE TESTS IN PRODUCTION
	
	These tests modify constants, which could 
	cause overwrites or cause serialized data to 
	become unrecognizable by later deserializers.
	
	There are no solutions as the tests could be run 
	in parallel w/ some other task.
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

-- remove userdata custom stuff
require("./src/userdata").setReader(nil)
require("./src/userdata").setWriter(nil)

local proxy = newproxy()

pair(1, "value")
pair(1, 5)
pair(1, vector.create(1, 2))
pair(1, proxy)

local Sir_String = serialize({ "value" })
local Sir_Number = serialize({ 5 })
local Sir_Vector = serialize({ vector.create(1, 2) })
local Sir_User = serialize({ proxy })

-- serialize
test.serial(Sir_String, test.newBuffer(197, 19, 10, 5, "value", 200))
test.serial(Sir_Number, test.newBuffer(197, 100, 90, 5, 200))
test.serial(Sir_Vector, test.newBuffer(197, 158, 144, 1, 2, 0, 200))
test.serial(Sir_User, test.newBuffer(197, 204, 203, 200)) -- ???

-- deserialize
test.compare("value", deserialize(Sir_String)[1])
test.compare(5, deserialize(Sir_Number)[1])
test.compare(vector.create(1, 2), deserialize(Sir_Vector)[1])
test.compare(proxy, deserialize(Sir_User)[1]) -- uh oh..?

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
