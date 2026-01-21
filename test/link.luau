--!strict
-- Runs tests for ../src/link

local link = require("../src/link")
local test = require("./test")

-- Serialize
local buf, pos, size = link.serialize(34, test.sizedBuffer(0), 0, 0)
test.serial(test.newBuffer(34, 0), buf)
test.compare(1, pos)
test.compare(2, size)

buf, pos, size = link.serialize(34, test.sizedBuffer(5), 2, 5)
test.serial(test.newBuffer(0, 0, 34, 0, 0), buf)
test.compare(3, pos)
test.compare(5, size)

buf, pos, size = link.serialize(16467, test.sizedBuffer(0), 0, 0)
test.serial(test.newBuffer(83, 64), buf)
test.compare(2, pos)
test.compare(2, size)

-- Calculate Ids
test.compare(19, link.calculateId(1, "string"))
test.compare(34, link.calculateId(16, "string"))
test.compare(50, link.calculateId(32, "string"))
test.compare(82, link.calculateId(64, "string"))
test.compare(16467, link.calculateId(128, "string"))
test.compare(114772, link.calculateId(512, "string"))

test.compare(100, link.calculateId(1, "number"))
test.compare(115, link.calculateId(16, "number"))
test.compare(131, link.calculateId(32, "number"))
test.compare(8324, link.calculateId(64, "number"))
test.compare(24708, link.calculateId(128, "number"))
test.compare(123013, link.calculateId(512, "number"))

test.compare(158, link.calculateId(1, "vector"))
test.compare(173, link.calculateId(16, "vector"))
test.compare(189, link.calculateId(32, "vector"))
test.compare(8382, link.calculateId(64, "vector"))
test.compare(24766, link.calculateId(128, "vector"))
test.compare(123071, link.calculateId(512, "vector"))

test.compare(204, link.calculateId(1, "userdata"))
test.compare(211, link.calculateId(8, "userdata"))
test.compare(5846, link.calculateId(32, "userdata"))
test.compare(14038, link.calculateId(64, "userdata"))
test.compare(30422, link.calculateId(128, "userdata"))
test.compare(128727, link.calculateId(512, "userdata"))

-- Validate type
test.compare("boolean", link.type(1))
test.compare("boolean", link.type(2))
test.compare("buffer", link.type(3))
test.compare("buffer", link.type(8))
test.compare("string", link.type(9))
test.compare("string", link.type(87))
test.compare("number", link.type(88))
test.compare("number", link.type(135))
test.compare("vector", link.type(136))
test.compare("vector", link.type(193))
test.compare("table", link.type(194))
test.compare("table", link.type(201))
test.compare("userdata", link.type(202))
test.compare("userdata", link.type(215))

-- Verify linkage
test.compare(true, link.islink(19, "string"))
test.compare(true, link.islink(34, "string"))
test.compare(true, link.islink(50, "string"))
test.compare(true, link.islink(82, "string"))
test.compare(true, link.islink(16467, "string"))
test.compare(true, link.islink(114772, "string"))

test.compare(true, link.islink(100, "number"))
test.compare(true, link.islink(115, "number"))
test.compare(true, link.islink(131, "number"))
test.compare(true, link.islink(8324, "number"))
test.compare(true, link.islink(24708, "number"))
test.compare(true, link.islink(123013, "number"))

test.compare(true, link.islink(158, "vector"))
test.compare(true, link.islink(173, "vector"))
test.compare(true, link.islink(189, "vector"))
test.compare(true, link.islink(8382, "vector"))
test.compare(true, link.islink(24766, "vector"))
test.compare(true, link.islink(123071, "vector"))

test.compare(true, link.islink(204, "userdata"))
test.compare(true, link.islink(219, "userdata"))
test.compare(true, link.islink(4316, "userdata"))
test.compare(true, link.islink(12508, "userdata"))
test.compare(true, link.islink(28892, "userdata"))
test.compare(true, link.islink(127197, "userdata"))

-- Verify duo-ality
test.compare(false, link.isduo(19, "string"))
test.compare(false, link.isduo(34, "string"))
test.compare(false, link.isduo(50, "string"))
test.compare(false, link.isduo(82, "string"))
test.compare(true, link.isduo(16467, "string"))
test.compare(true, link.isduo(114772, "string"))

test.compare(false, link.isduo(100, "number"))
test.compare(false, link.isduo(115, "number"))
test.compare(false, link.isduo(131, "number"))
test.compare(true, link.isduo(8324, "number"))
test.compare(true, link.isduo(24708, "number"))
test.compare(true, link.isduo(123013, "number"))

test.compare(false, link.isduo(158, "vector"))
test.compare(false, link.isduo(173, "vector"))
test.compare(false, link.isduo(189, "vector"))
test.compare(true, link.isduo(8382, "vector"))
test.compare(true, link.isduo(24766, "vector"))
test.compare(true, link.isduo(123071, "vector"))

test.compare(false, link.isduo(204, "userdata"))
test.compare(false, link.isduo(213, "userdata"))
test.compare(true, link.isduo(4316, "userdata"))
test.compare(true, link.isduo(12508, "userdata"))
test.compare(true, link.isduo(28892, "userdata"))
test.compare(true, link.isduo(127197, "userdata"))

-- Verify set
test.compare(false, pcall(link.set, 1, 1))
test.compare(false, pcall(link.set, 1, link.calculateId(0, "number")))
test.compare(false, pcall(link.set, 1, link.calculateId(32, "number") + 1))
test.compare(false, pcall(link.set, 1, link.calculateId(33, "number") - 1))
test.compare(false, pcall(link.set, 1, link.calculateId(33, "number") + 1))
test.compare(false, pcall(link.set, 1, link.calculateId(1055, "number") - 1))
test.compare(false, pcall(link.set, 1, link.calculateId(1055, "number") + 1))
test.compare(false, pcall(link.set, 1, link.calculateId(1056, "number")))

return {}
