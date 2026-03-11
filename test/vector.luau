--!strict
-- Runs tests for ../src/vector

local test = require("./test")
local vcreate = vector.create
local ZERO = 142
local ONE = 143
local X = 144
local Y = 145
local Z = 146
local XY = 147
local XZ = 148
local YZ = 149
local BYTE = 150
local CHAR = 151
local TRYTE = 152
local FLOAT = 153
local NUMBER = 154
local SCALAR = 155

-- Check that vector.luau works properly
test.compare(test.newBuffer(ZERO), test.inspect(vector.zero))
test.compare(test.newBuffer(ONE), test.inspect(vector.one))
test.compare(test.newBuffer(X), test.inspect(vcreate(1, 0)))
test.compare(test.newBuffer(Y), test.inspect(vcreate(0, 1)))
test.compare(test.newBuffer(Z), test.inspect(vcreate(0, 0, 1)))
test.compare(test.newBuffer(XY), test.inspect(vcreate(1, 1)))
test.compare(test.newBuffer(XZ), test.inspect(vcreate(1, 0, 1)))
test.compare(test.newBuffer(YZ), test.inspect(vcreate(0, 1, 1)))
test.compare(test.newBuffer(BYTE, 2, 3, 4), test.inspect(vcreate(2, 3, 4)))
test.compare(
	test.newBuffer(CHAR, 0, 1, 0, 2, 0, 4),
	test.inspect(vcreate(2 ^ 8, 2 ^ 9, 2 ^ 10))
)
test.compare(
	test.newBuffer(TRYTE, 0, 0, 1, 0, 0, 2, 0, 0, 4),
	test.inspect(vcreate(2 ^ 16, 2 ^ 17, 2 ^ 18))
)
test.compare(
	test.newBuffer(TRYTE, 0, 0, 255, 0, 0, 254, 0, 0, 252),
	test.inspect(vcreate(-2 ^ 16, -2 ^ 17, -2 ^ 18))
)
test.compare(
	test.newBuffer(FLOAT, 0, 0, 128, 75, 0, 0, 0, 76, 0, 0, 128, 76),
	test.inspect(vcreate(2 ^ 24, 2 ^ 25, 2 ^ 26))
)
test.compare(
	test.newBuffer(NUMBER, 99, 2, 100, 0, 1, 101, 0, 0, 1),
	test.inspect(vcreate(2, 2 ^ 8, 2 ^ 16))
)
test.compare(test.newBuffer(SCALAR, 144, 99, 2), test.inspect(vcreate(2, 0, 0)))

-- error checks
local vecDeserialize = require("../src/vector").deserialize
test.compare(false, pcall(vecDeserialize, test.newBuffer(0), 0)) -- failure to parse vector

return {}
