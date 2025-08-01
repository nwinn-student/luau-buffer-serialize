--!optimize 2
local enumerator = require("./pointer/Enumerator")
type BufferData = enumerator.BufferData
type PositionData = enumerator.PositionData

local numSerializer
local numDeserializer

do
	local num = require("./number")
	numSerializer = num.serialize
	numDeserializer = num.deserialize
end

local grow = enumerator.Methods.grow

enumerator = nil

local EMPTY = 9
local BYTE = 10
local CHAR = 11
local THREE_BYTE = 12
local INT = 13
local CONCAT_STR_NUM = 14
local CONCAT_NUM_STR = 15
local NUM = 16

local READ = {}
local WRITE = {} -- 1 to 1343

@native
local function strSerializer(value: string, data: BufferData)
	local buf = data.Data
	local pos = data.Position or 0

	if value == "" then
		buf = grow(buf, data, 1)
		buffer.writeu8(buf, pos, EMPTY)
		return
	end

	local cachedConstant: number? = WRITE[value]
	if cachedConstant then
		local newSize = if cachedConstant <= 64 then 1
			else 2

		buf = grow(buf, data, newSize)

		if newSize == 1 then
			buffer.writeu8(buf, pos, cachedConstant + 18)
		else
			local constVal = cachedConstant - 64
			buffer.writeu8(buf, pos, 83 + (constVal // 256) )
			buffer.writeu8(buf, pos+1, constVal)
		end

		return
	end

	local len = #value

	-- strings larger will take less time, may change to only support constant strings
	if len <= 32 then
		-- for all decimal numbers use "%-?%d*%.?%d+e?%-?%d*" (not perfect)
		--								<-123.521> <e-53>
		-- we just want positive integers (it is 2+x faster than above)
		local start, finish = string.find(value, "%d+")
		if start == 1 and finish == len then -- <num>
			buf = grow(buf, data, 1)
			buffer.writeu8(buf, pos, NUM)
			numSerializer(tonumber(value), data)
		elseif start ~= 1 and finish == len then -- <str><num>
			buf = grow(buf, data, 1)
			buffer.writeu8(buf, pos, CONCAT_STR_NUM)
			strSerializer(string.sub(value, 1, start-1), data)
			numSerializer(tonumber(string.sub(value, start)), data)
			return
		elseif start == 1 and finish ~= len then -- <num><str>
			-- there exist cases where it could be <num><str><num>
			-- in those cases.. it can become much slower
			buf = grow(buf, data, 1)
			buffer.writeu8(buf, pos, CONCAT_NUM_STR)
			numSerializer(tonumber(string.sub(value, 1, finish)), data)
			strSerializer(string.sub(value, finish + 1), data)
			return
		end
	end

	local newSize = if len < 256 then 2
		elseif len < 65_536 then 3
		elseif len < 16_777_216 then 4
		else 5

	buf = grow(buf, data, len + newSize)
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

	buffer.writestring(buf, pos + newSize, value, len)
end

@native
local function strDeserializer(buf: buffer, data: PositionData)
	local pos = data.Position
	local id = buffer.readu8(buf, pos)

	if id == EMPTY then
		data.Position += 1
		return ''
	end

	local cachedId = if id > 82 then (id - 82) * 256 + 64
		else id - 18

	local cachedConstant = READ[cachedId]
	if cachedConstant then
		data.Position += if cachedId > 64 then 2 else 1
		return cachedConstant
	end

	if id == CONCAT_NUM_STR then
		data.Position += 1
		local numVal = numDeserializer(buf, data)
		local strVal = strDeserializer(buf, data)
		if numVal and strVal then
			return numVal .. strVal
		end
		return nil -- data corrupted
	elseif id == CONCAT_STR_NUM then
		data.Position += 1
		local strVal = strDeserializer(buf, data)
		local numVal = numDeserializer(buf, data)
		if numVal and strVal then
			return strVal .. numVal
		end
		return nil -- data corrupted
	elseif id == NUM then
		data.Position += 1
		local numVal = numDeserializer(buf, data)
		if numVal then
			return tostring(numVal)
		end
		return nil -- data corrupted
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
		data.Position += 1
		return nil -- for future version
	end
	
	data.Position += len + lenSize + 1
	return buffer.readstring(buf, pos + lenSize + 1, len)
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
	String.Read = WRITE
end

return String