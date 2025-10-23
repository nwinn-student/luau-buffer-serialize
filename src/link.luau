--!optimize 2
--!strict

local inflate = require("./inflate")

local link = {}

-- possibly used in table?
local STRING_COUNT = 64
local NUMBER_COUNT = 32
local VECTOR_COUNT = 32
local USER_COUNT = 16

local STRING_START = 18
local NUMBER_START = 99
local VECTOR_START = 157
local USER_START = 203

local STRING_DUOSTART = 83
local NUMBER_DUOSTART = 132
local VECTOR_DUOSTART = 190
local USER_DUOSTART = 220

-- string: 1 to 1343
-- number: 1 to 1055
-- vector: 1 to 1055
-- userdata: 1 to 1039

link.values = {}

@native
function link.serialize(value: number, buf: buffer, pos: number, size: number)
	if pos + 2 > size then
		buf, size = inflate(buf, pos + 2, size)
	end
	buffer.writeu16(buf, pos, value)
	return buf, pos + (value > 255 and 2 or 1), size, value :: any
end

type TYPES = "userdata" | "number" | "string" | "vector"

@native
function link.calculateId(id: number, typeV: TYPES)
	local count = if typeV == "string"
		then STRING_COUNT
		elseif typeV == "number" then NUMBER_COUNT
		elseif typeV == "vector" then VECTOR_COUNT
		else USER_COUNT

	local start = if typeV == "string"
		then STRING_START
		elseif typeV == "number" then NUMBER_START
		elseif typeV == "vector" then VECTOR_START
		else USER_START

	local duostart = if typeV == "string"
		then STRING_DUOSTART
		elseif typeV == "number" then NUMBER_DUOSTART
		elseif typeV == "vector" then VECTOR_DUOSTART
		else USER_DUOSTART

	local calcId
	local newSize = if id <= count then 1 else 2

	if newSize == 1 then
		calcId = id + start
	else
		local constVal = id - count
		calcId = constVal * 256 + (duostart + constVal // 256)
	end

	return calcId
end

return link
