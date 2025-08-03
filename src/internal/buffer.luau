--!optimize 2
local enumerator = require("./pointer/Enumerator")
type BufferData = enumerator.BufferData
type PositionData = enumerator.PositionData

local grow = enumerator.Methods.grow

enumerator = nil

local EMPTY = 3
local BYTE = 4
local CHAR = 5
local THREE_BYTE = 6
local INT = 7

local EMPTY_BUFFER = buffer.create(0)

return {
	serialize = function(value: buffer, data: BufferData)
		local len = buffer.len(value)
		local buf = data.Data
		local pos = data.Position or 0

		if len == 0 then
			buf = grow(buf, data, 1)
			buffer.writeu8(buf, pos, EMPTY)
			return
		end

		local newSize = if len < 256 then 2
			elseif len < 65_536 then 3
			elseif len < 16_777_216 then 4
			else 5

		buf = grow(buf, data, len + newSize)
		buffer.writeu8(buf, pos, 2 + newSize)

		if len < 256 then
			buffer.writeu8(buf, pos + 1, len)
		elseif len < 65_536 then
			buffer.writeu16(buf, pos + 1, len)
		elseif len < 16_777_216 then
			buffer.writebits(buf, (pos + 1)*8, (pos + 1)*8 + 16, len)
		else
			buffer.writeu32(buf, pos + 1, len)
		end

		buffer.copy(buf, pos + newSize, value)
	end,
	deserialize = function(buf: buffer, data: PositionData)
		local pos = data.Position
		local id = buffer.readu8(buf, pos)
		
		if id == EMPTY then
			data.Position += 1
			return EMPTY_BUFFER
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
			local posbits = 8*pos
			len = buffer.readbits(buf, posbits, 24)
			pos += lenSize
		elseif id == INT then
			len = buffer.readu32(buf, pos)
			pos += lenSize
		end

		local value = buffer.create(len)
		buffer.copy(value, 0, buf, pos, len)
		data.Position += len + lenSize + 1
		return value
	end
}
