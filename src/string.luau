--!optimize 2
--!strict
local inflate = require("./inflate")

local EMPTY = 8
local BYTE = 9
local CHAR = 10
local THREE_BYTE = 11
local INT = 12
local STRING_15 = 27

local READ = {}
local WRITE = {} -- 1 to 1343

@native
local function strSerializer(value: string, buf: buffer, pos :number, size: number)

	if value == "" then
		if not buf then
			buf, size = buffer.create(1), 1
		elseif pos + 1 > size then
			buf, size = inflate(buf, pos + 1, size)
		end
		buffer.writeu8(buf, pos, EMPTY)
		return buf, pos + 1, size
	end

	local cachedConstant: number? = WRITE[value]
	if cachedConstant then
		local newSize = if cachedConstant <= 64 then
				1
			else
				2
		
		if not buf then
			buf, size = buffer.create(newSize), newSize
		elseif pos + newSize > size then
			buf, size = inflate(buf, pos + newSize, size)
		end

		if newSize == 1 then
			buffer.writeu8(buf, pos, cachedConstant + STRING_15)
		else
			local constVal = cachedConstant - 64
			buffer.writeu8(buf, pos, 92 + (constVal // 256) )
			buffer.writeu8(buf, pos + 1, constVal)
		end

		return buf, pos + newSize, size
	end

	local len = #value

	local newSize = if len < 16 then 1
		elseif len < 256 then 2
		elseif len < 65_536 then 3
		elseif len < 16_777_216 then 4
		else 5
	
	if not buf then
		buf, size = buffer.create(len + newSize), len + newSize
	elseif pos + len + newSize > size then
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
		buffer.writebits(buf, (pos + 1)*8, 24, len)		
	else
		buffer.writeu32(buf, pos + 1, len)
	end

	buffer.writestring(buf, pos + newSize, value :: string, len)
	return buf, pos + newSize + len, size
end

@native
local function strDeserializer(buf: buffer, pos: number): (string?, number)
	local id = buffer.readu8(buf, pos)

	if id == EMPTY then
		return '', pos + 1
	end
	
	if id > STRING_15 then
		local cachedId = if id > 91 then
				(id - 91) * 256 + 64
			else
				id - STRING_15

		local cachedConstant: string? = READ[cachedId]
		if cachedConstant then
			return cachedConstant, 
				pos + (if cachedId > 64 then 2 else 1)
		end
		
		error(`Failed to parse string constant with id: {
					cachedId
				} ({id}) at position {
					pos
				}`)
	end
	
	if id > INT then
		return buffer.readstring(buf, pos + 1, id - INT),
			pos + id - INT + 1
	end
	
	local lenSize = id - EMPTY

	local len = if id == BYTE then
			buffer.readu8(buf, pos + 1)
		elseif id == CHAR then
			buffer.readu16(buf, pos + 1)
		elseif id == THREE_BYTE then
			buffer.readbits(buf, (pos + 1)*8, 24)
		else -- id == INT
			buffer.readu32(buf, pos + 1)		
	
	return buffer.readstring(buf, pos + lenSize + 1, len), 
		pos + len + 1 + lenSize
end

local String = {
	Read = READ,
	Write = WRITE,

	serialize = strSerializer,
	deserialize = strDeserializer
}

--[[
	Clears and replaces the read table
	
	@ Mainly used to reduce memory usage
]]--
function String.resetRead()
	table.clear(READ)
	READ = {}
	String.Read = READ
end
--[[
	Clears and replaces the write table
	
	@ Mainly used to reduce memory usage
]]--
function String.resetWrite()
	table.clear(WRITE)
	WRITE = {}
	String.Write = WRITE
end

return String
