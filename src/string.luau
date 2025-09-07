--!optimize 2
--!strict
local inflate = require("./inflate")

local EMPTY = 8
local BYTE = 9
local CHAR = 10
local THREE_BYTE = 11
local INT = 12
local STRING_1 = 13
local STRING_2 = 14
local STRING_3 = 15
local STRING_4 = 16
local STRING_5 = 17
local STRING_6 = 18
local STRING_7 = 19
local STRING_8 = 20
local STRING_9 = 21
local STRING_10 = 22
local STRING_11 = 23
local STRING_12 = 24
local STRING_13 = 25
local STRING_14 = 26
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
		local newSize = if cachedConstant <= 64 then 1
			else 2
		
		if not buf then
			buf, size = buffer.create(newSize), newSize
		elseif pos + newSize > size then
			buf, size = inflate(buf, pos + newSize, size)
		end

		if newSize == 1 then
			buffer.writeu8(buf, pos, cachedConstant + 27)
		else
			local constVal = cachedConstant - 64
			buffer.writeu8(buf, pos, 92 + (constVal // 256) )
			buffer.writeu8(buf, pos + 1, constVal)
		end

		return buf, pos + newSize, size
	end

	local len = #value

	local newSize = if len < 256 then 2
		elseif len < 65_536 then 3
		elseif len < 16_777_216 then 4
		else 5
	
	if not buf then
		buf, size = buffer.create(len + newSize), len + newSize
	elseif pos + len + newSize > size then
		buf, size = inflate(buf, pos + len + newSize, size)
	end
	buffer.writeu8(buf, pos, 8 + newSize)

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

	local cachedId = if id > 91 then (id - 91) * 256 + 64
		else id - 27

	local cachedConstant: string? = READ[cachedId]
	if cachedConstant then
		return cachedConstant, pos + (if cachedId > 64 then 2 else 1)
	end

	local lenSize = id - EMPTY

	local len: number

	if id == BYTE then
		len = buffer.readu8(buf, pos + 1)
	elseif id == CHAR then
		len = buffer.readu16(buf, pos + 1)
	elseif id == THREE_BYTE then
		len = buffer.readbits(buf, (pos + 1)*8, 24)
	elseif id == INT then
		len = buffer.readu32(buf, pos + 1)
	else
		-- DATA CORRUPTED (for now)
		-- we want to error later**
		-- we know it is an error from constants
		return nil, pos + 1 -- for future version
	end

	return buffer.readstring(buf, pos + lenSize + 1, len), pos + len + 1 + lenSize
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
