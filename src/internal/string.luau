--!optimize 2
local enumerator = require("./pointer/Enumerator")

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
local function strSerializer(value: string, buf: buffer, pos :number)

	if value == "" then
		buf = grow(buf, pos, 1)
		buffer.writeu8(buf, pos, EMPTY)
		return buf, pos + 1
	end
	
	local cachedConstant: number? = WRITE[value]
	if cachedConstant then
		local newSize = if cachedConstant <= 64 then 1
			else 2
		
		buf = grow(buf, pos, newSize)

		if newSize == 1 then
			buffer.writeu8(buf, pos, cachedConstant + 18)
		else
			local constVal = cachedConstant - 64
			buffer.writeu8(buf, pos, 83 + (constVal // 256) )
			buffer.writeu8(buf, pos+1, constVal)
		end

		return buf, pos + newSize
	end

	local len = #value

	-- strings larger will take less time, may change to only support constant strings
	if len <= 32 then
		-- for all decimal numbers use "%-?%d*%.?%d+e?%-?%d*" (not perfect)
		--								<-123.521> <e-53>
		-- we just want positive integers (it is 2+x faster than above)
		local start, finish = string.find(value, "%d+")

		if start == 1 and finish == len then -- <num>
			buf = grow(buf, pos, 1)
			buffer.writeu8(buf, pos, NUM)
			return numSerializer(tonumber(value), buf, pos + 1)
		elseif start and finish and finish - start > 1 then
			if start ~= 1 and finish == len then -- <str><num>
				buf = grow(buf, pos, 1)
				buffer.writeu8(buf, pos, CONCAT_STR_NUM)
				return numSerializer(tonumber(string.sub(value, start)), 
					strSerializer(string.sub(value, 1, start-1), buf, pos + 1)
				)
			elseif start == 1 and finish ~= len then -- <num><str>
				-- there exist cases where it could be <num><str><num>
				-- in those cases.. it can become much slower
				buf = grow(buf, pos, 1)
				buffer.writeu8(buf, pos, CONCAT_NUM_STR)
				return strSerializer(string.sub(value, finish + 1), 
					numSerializer(tonumber(string.sub(value, 1, finish)), buf, pos + 1)
				)
			end
		else
			-- str MUST be a constant for any value
			if start ~= 1 and finish == len then -- <str><num>
				local str = string.sub(value, 1, start-1)
				local cachedConstant = WRITE[str]
				if cachedConstant then
					local newSize = if cachedConstant <= 64 then 2
						else 3
					buf = grow(buf, pos, newSize)
					buffer.writeu8(buf, pos, CONCAT_STR_NUM)

					if newSize == 1 then
						buffer.writeu8(buf, pos + 1, cachedConstant + 18)
					else
						local constVal = cachedConstant - 64
						buffer.writeu8(buf, pos + 1, 83 + (constVal // 256) )
						buffer.writeu8(buf, pos + 2, constVal)
					end
					return numSerializer(tonumber(string.sub(value, start)), buf, pos + newSize)
				end
			elseif start == 1 and finish ~= len then -- <num><str>
				local str = string.sub(value, finish + 1)
				local cachedConstant = WRITE[str]
				if cachedConstant then
					buf = grow(buf, pos, 1)
					buffer.writeu8(buf, pos, CONCAT_NUM_STR)
					buf, pos = numSerializer(tonumber(string.sub(value, 1, finish)), buf, pos + 1)
					local newSize = if cachedConstant <= 64 then 1
						else 2
					buf = grow(buf, pos, newSize)
					
					if newSize == 1 then
						buffer.writeu8(buf, pos + 1, cachedConstant + 18)
					else
						local constVal = cachedConstant - 64
						buffer.writeu8(buf, pos + 1, 83 + (constVal // 256) )
						buffer.writeu8(buf, pos + 2, constVal)
					end
					return buf, pos + newSize
				end
			end
		end
		
	end

	local newSize = if len < 256 then 2
		elseif len < 65_536 then 3
		elseif len < 16_777_216 then 4
		else 5

	buf = grow(buf, pos, len + newSize)
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
	return buf, pos + newSize + len
end

@native
local function strDeserializer(buf: buffer, pos: number)
	local id = buffer.readu8(buf, pos)

	if id == EMPTY then
		return '', pos + 1
	end

	local cachedId = if id > 82 then (id - 82) * 256 + 64
		else id - 18

	local cachedConstant = READ[cachedId]
	if cachedConstant then
		return cachedConstant, pos + (if cachedId > 64 then 2 else 1)
	end

	if id == CONCAT_NUM_STR then
		local numVal, pos = numDeserializer(buf, pos + 1)
		local strVal, pos = strDeserializer(buf, pos)
		if numVal and strVal then
			return numVal .. strVal, pos
		end
		return nil, pos + 1 -- data corrupted
	elseif id == CONCAT_STR_NUM then
		local strVal, pos = strDeserializer(buf, pos + 1)
		local numVal, pos = numDeserializer(buf, pos)
		if numVal and strVal then
			return strVal .. numVal, pos
		end
		return nil, pos + 1 -- data corrupted
	elseif id == NUM then
		local numVal, pos = numDeserializer(buf, pos + 1)
		if numVal then
			return tostring(numVal), pos
		end
		return nil, pos + 1 -- data corrupted
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
	String.Read = WRITE
end

return String