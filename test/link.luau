--!strict
-- Runs tests for ../BufferSerializer/link

local link = require("../src/link")
local test = require("./test")

-- Calculate Ids
test.compare(100, link.calculateId(1, "number"))
test.compare(8580, link.calculateId(65, "number"))

-- Validate type
test.compare("number", link.type(100))

test.compare(true, link.islink(100, "number"))
test.compare(false, link.isduo(100, "number"))

return {}
