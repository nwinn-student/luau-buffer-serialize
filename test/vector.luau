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
local serialize = require("../src").serialize
local deserialize = require("../src").deserialize

local Sir_Zero = serialize(vector.zero)
local Sir_One = serialize(vector.one)
local Sir_X = serialize(vcreate(1, 0))
local Sir_Y = serialize(vcreate(0, 1))
local Sir_Z = serialize(vcreate(0, 0, 1))
local Sir_XY = serialize(vcreate(1, 1))
local Sir_XZ = serialize(vcreate(1, 0, 1))
local Sir_YZ = serialize(vcreate(0, 1, 1))
local Sir_Byte = serialize(vcreate(2, 3, 4))
local Sir_Char = serialize(vcreate(2 ^ 8, 2 ^ 9, 2 ^ 10))
local Sir_Tryte = serialize(vcreate(2 ^ 16, 2 ^ 17, 2 ^ 18))
local Sir_InvTryte = serialize(vcreate(-2 ^ 16, -2 ^ 17, -2 ^ 18))
local Sir_Float = serialize(vcreate(2 ^ 24, 2 ^ 25, 2 ^ 26))
local Sir_Number = serialize(vcreate(2, 2 ^ 8, 2 ^ 16))
local Sir_Scalar = serialize(vcreate(2, 0, 0))

-- serialization
test.serial(Sir_Zero, test.newBuffer(ZERO))
test.serial(Sir_One, test.newBuffer(ONE))
test.serial(Sir_X, test.newBuffer(X))
test.serial(Sir_Y, test.newBuffer(Y))
test.serial(Sir_Z, test.newBuffer(Z))
test.serial(Sir_XY, test.newBuffer(XY))
test.serial(Sir_XZ, test.newBuffer(XZ))
test.serial(Sir_YZ, test.newBuffer(YZ))
test.serial(Sir_Byte, test.newBuffer(BYTE, 2, 3, 4))
test.serial(Sir_Char, test.newBuffer(CHAR, 0, 1, 0, 2, 0, 4))
test.serial(Sir_Tryte, test.newBuffer(TRYTE, 0, 0, 1, 0, 0, 2, 0, 0, 4))
test.serial(Sir_InvTryte, test.newBuffer(TRYTE, 0, 0, 255, 0, 0, 254, 0, 0, 252))
test.serial(
	Sir_Float,
	test.newBuffer(FLOAT, 0, 0, 128, 75, 0, 0, 0, 76, 0, 0, 128, 76)
)
test.serial(Sir_Number, test.newBuffer(NUMBER, 99, 2, 100, 0, 1, 101, 0, 0, 1))
test.serial(Sir_Scalar, test.newBuffer(SCALAR, 144, 99, 2))

-- deserialization
test.compare(vector.zero, deserialize(Sir_Zero))
test.compare(vector.one, deserialize(Sir_One))
test.compare(vcreate(1, 0), deserialize(Sir_X))
test.compare(vcreate(0, 1), deserialize(Sir_Y))
test.compare(vcreate(0, 0, 1), deserialize(Sir_Z))
test.compare(vcreate(1, 1), deserialize(Sir_XY))
test.compare(vcreate(1, 0, 1), deserialize(Sir_XZ))
test.compare(vcreate(0, 1, 1), deserialize(Sir_YZ))
test.compare(vcreate(2, 3, 4), deserialize(Sir_Byte))
test.compare(vcreate(2 ^ 8, 2 ^ 9, 2 ^ 10), deserialize(Sir_Char))
test.compare(vcreate(2 ^ 16, 2 ^ 17, 2 ^ 18), deserialize(Sir_Tryte))
test.compare(vcreate(-2 ^ 16, -2 ^ 17, -2 ^ 18), deserialize(Sir_InvTryte))
test.compare(vcreate(2 ^ 24, 2 ^ 25, 2 ^ 26), deserialize(Sir_Float))
test.compare(vcreate(2, 2 ^ 8, 2 ^ 16), deserialize(Sir_Number))
test.compare(vcreate(2, 0, 0), deserialize(Sir_Scalar))

-- error checks
local vecDeserialize = require("../src/vector").deserialize
test.compare(false, pcall(vecDeserialize, test.newBuffer(0), 0)) -- failure to parse vector

return {}
