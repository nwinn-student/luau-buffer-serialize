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

local test = require("@self/test")

local pair = require("./src").pair
local serialize = require("./src").serialize
local deserialize = require("./src").deserialize

-- Now we need to test pair

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
