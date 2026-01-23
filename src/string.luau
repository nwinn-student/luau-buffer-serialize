--!optimize 2
--!strict
local inflate = require("./inflate")

local EMPTY = 8
local BYTE = 9
local CHAR = 10
local THREE_BYTE = 11
local INT = 12
local STRING_15 = 27

@native
local function strSerializer(
	value: string,
	buf: buffer,
	pos: number,
	size: number
)
	if value == "" then
		if pos + 1 > size then
			buf, size = inflate(buf, pos + 1, size)
		end
		buffer.writeu8(buf, pos, EMPTY)
		return buf, pos + 1, size
	end

	local len = #value

	local newSize = if len < 16
		then 1
		elseif len < 256 then 2
		elseif len < 65_536 then 3
		elseif len < 16_777_216 then 4
		else 5

	if pos + len + newSize > size then
		buf, size = inflate(buf, pos + len + newSize, size)
	end

	if len < 16 then
		buffer.writeu8(buf, pos, INT + len)
		buffer.writestring(buf, pos + 1, value :: string, len)
		return buf, pos + 1 + len, size
	end

	buffer.writeu8(buf, pos, 7 + newSize)

	if len < 256 then
		buffer.writeu8(buf, pos + 1, len)
	elseif len < 65_536 then
		buffer.writeu16(buf, pos + 1, len)
	elseif len < 16_777_216 then
		buffer.writebits(buf, (pos + 1) * 8, 24, len)
	else
		buffer.writeu32(buf, pos + 1, len)
	end

	buffer.writestring(buf, pos + newSize, value :: string, len)
	return buf, pos + newSize + len, size
end

--[[
	Produces a string from the buffer starting at the given position.

	@param buf buffer containing the string
	@param pos the starting position of the string

	@error Failed to parse string
	@error buffer access out of bounds

	@return the string and the end string position + 1
]]
@native
local function strDeserializer(buf: buffer, pos: number)
	local id = buffer.readu8(buf, pos)

	if id == EMPTY then
		return "", pos + 1
	end

	if id > INT and id <= STRING_15 then
		return buffer.readstring(buf, pos + 1, id - INT), pos + id - INT + 1
	end

	local lenSize = id - EMPTY

	local len: number

	if id == BYTE then
		len = buffer.readu8(buf, pos + 1)
	elseif id == CHAR then
		len = buffer.readu16(buf, pos + 1)
	elseif id == THREE_BYTE then
		len = buffer.readbits(buf, (pos + 1) * 8, 24)
	elseif id == INT then
		len = buffer.readu32(buf, pos + 1)
	else
		error(`Failed to parse string using byte: {id} at position {pos}`)
	end

	return buffer.readstring(buf, pos + lenSize + 1, len), pos + len + 1 + lenSize
end

local String = {
	serialize = strSerializer,
	deserialize = strDeserializer,
}

return table.freeze(String)
