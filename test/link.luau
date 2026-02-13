--!strict
-- Runs tests for ../src/link

local link = require("../src/link")
local test = require("./test")

-- Validate type
test.compare("boolean", link.type(1))
test.compare("boolean", link.type(2))
test.compare("buffer", link.type(3))
test.compare("buffer", link.type(7))
test.compare("string", link.type(8))
test.compare("string", link.type(96))
test.compare("number", link.type(97))
test.compare("number", link.type(141))
test.compare("vector", link.type(142))
test.compare("vector", link.type(193))
test.compare("table", link.type(194))
test.compare("table", link.type(201))
test.compare("userdata", link.type(202))
test.compare("userdata", link.type(215))

-- Verify linkage
test.compare(true, link.islink(28, "string"))
test.compare(true, link.islink(43, "string"))
test.compare(true, link.islink(59, "string"))
test.compare(true, link.islink(91, "string"))
test.compare(true, link.islink(16476, "string"))
test.compare(true, link.islink(114781, "string"))

test.compare(true, link.islink(106, "number"))
test.compare(true, link.islink(121, "number"))
test.compare(true, link.islink(137, "number"))
test.compare(true, link.islink(8330, "number"))
test.compare(true, link.islink(24714, "number"))
test.compare(true, link.islink(123019, "number"))

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
test.compare(false, link.isduo(28, "string"))
test.compare(false, link.isduo(43, "string"))
test.compare(false, link.isduo(59, "string"))
test.compare(false, link.isduo(91, "string"))
test.compare(true, link.isduo(16476, "string"))
test.compare(true, link.isduo(114781, "string"))

test.compare(false, link.isduo(106, "number"))
test.compare(false, link.isduo(121, "number"))
test.compare(false, link.isduo(137, "number"))
test.compare(true, link.isduo(8330, "number"))
test.compare(true, link.isduo(24714, "number"))
test.compare(true, link.isduo(123019, "number"))

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

return {}
