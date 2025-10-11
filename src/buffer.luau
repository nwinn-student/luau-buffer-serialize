--!optimize 2
--!strict
local inflate = require("./inflate")

local EMPTY = 3
local BYTE = 4
local CHAR = 5
local THREE_BYTE = 6
local INT = 7

local EMPTY_BUFFER = buffer.create(0)

return {
	serialize = function(value: buffer, buf: buffer, pos: number, size: number)
		local len = buffer.len(value)

		if len == 0 then
			if pos + 1 > size then
				buf, size = inflate(buf, pos + 1, size)
			end
			buffer.writeu8(buf, pos, EMPTY)
			return buf, pos + 1, size
		end

		local newSize = if len < 256 then 2 elseif len < 65_536 then 3 elseif len < 16_777_216 then 4 else 5

		if pos + len + newSize > size then
			buf, size = inflate(buf, pos + len + newSize, size)
		end
		buffer.writeu8(buf, pos, 2 + newSize)

		if len < 256 then
			buffer.writeu8(buf, pos + 1, len)
		elseif len < 65_536 then
			buffer.writeu16(buf, pos + 1, len)
		elseif len < 16_777_216 then
			buffer.writebits(buf, (pos + 1) * 8, (pos + 1) * 8 + 16, len)
		else
			buffer.writeu32(buf, pos + 1, len)
		end

		buffer.copy(buf, pos + newSize, value)
		return buf, pos + newSize + len, size
	end,
	deserialize = function(buf: buffer, pos: number)
		local id = buffer.readu8(buf, pos)

		if id == EMPTY then
			return EMPTY_BUFFER, pos + 1
		end

		pos += 1

		local lenSize = id - EMPTY

		local len: number
		if id == BYTE then
			len = buffer.readu8(buf, pos)
			pos += lenSize
		elseif id == CHAR then
			len = buffer.readu16(buf, pos)
			pos += lenSize
		elseif id == THREE_BYTE then
			len = buffer.readbits(buf, 8 * pos, 24)
			pos += lenSize
		elseif id == INT then
			len = buffer.readu32(buf, pos)
			pos += lenSize
		end

		local value = buffer.create(len)
		buffer.copy(value, 0, buf, pos, len)
		return value, pos + len
	end,
}
