--!strict
--!optimize 2

local inflate = require("./inflate")
local numSerializer = require("./number").serialize
local numDeserializer = require("./number").deserialize

-- ???
local NUMBER = 232
local INTEGER = 233

local MAX_INT = 2 ^ 31 - 1
local MIN_INT = -2 ^ 31

local function integerSerializer(value: integer, buf: buffer, pos: number, size: number)
	local trimmedNumber = integer.tonumber(value)
	if MIN_INT <= trimmedNumber and trimmedNumber <= MAX_INT then
		if pos + 1 > size then
			buf, size = inflate(buf, pos + 1, size)
		end

		buffer.writeu8(buf, pos, NUMBER)

		return numSerializer(trimmedNumber, buf, pos + 1, size)
	end

	if pos + 9 > size then
		buf, size = inflate(buf, pos + 9, size)
	end

	buffer.writeu8(buf, pos, INTEGER)
	buffer.writeinteger(buf, pos + 1, value)

	return buf, pos + 9, size
end

local function integerDeserializer(buf: buffer, pos: number): integer
	local id = buffer.readu8(buf, pos)
	if id == NUMBER then
		local int
		int, pos = numDeserialize(buf, pos + 1)
		return integer.create(int), pos
	elseif id == INTEGER then
		return buffer.readinteger(buf, pos + 1), pos + 9
	end
	-- TODO: Error
	error(`insert text here`)
end

return table.freeze({
	serialize = integerSerializer,
	deserialize = integerDeserializer,
})