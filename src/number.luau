--!optimize 2
--!strict
local inflate = require("./inflate")

local ZERO = 88
local ONE = 89
local BYTE = 90
local CHAR = 91
local THREE_BYTE = 92
local INT = 93
local FLOAT = 94
local DOUBLE = 95
local NAN = 96

local MIN_BYTE = -2^7
local MAX_BYTE = 2^7-1

local MIN_CHAR = -2^15
local MAX_CHAR = 2^15-1

local MIN_THREE = -2^23
local MAX_THREE = 2^23-1

local MIN_INT = -2^31
local MAX_INT = 2^31-1

local MAX_FLOAT = 2^127

local vecX = vector.create(1, 0)

-- Shrink mode is not well documented as of writing
local READ = {}
local WRITE = {} -- 1 to 1055

@native
local function numSerializer(value: number, buf: buffer, pos: number, size: number)

	if value == 0 or value == 1 or value ~= value then
		if pos + 1 > size then
			buf, size = inflate(buf, pos + 1, size)
		end
		
		buffer.writeu8(buf, pos, if value == 0 then
				ZERO
			elseif value == 1 then
				ONE
			else 
				NAN)
		
		return buf, pos + 1, size
	end

	local cachedConstant: number? = WRITE[value]
	if cachedConstant then
		local newSize = if cachedConstant <= 32 then
				1
			else
				2
		
		if pos + newSize > size then
			buf, size = inflate(buf, pos + newSize, size)
		end

		if newSize == 1 then
			buffer.writeu8(buf, pos, cachedConstant + 99)
		else
			local constVal = cachedConstant - 32
			buffer.writeu8(buf, pos, 132 + (constVal // 256) )
			buffer.writeu8(buf, pos+1, constVal)
		end

		return buf, pos + newSize, size
	end

	-- Floating points
	if value % 1 ~= 0 or value > MAX_INT or value < MIN_INT then

		if MAX_FLOAT < value or value < -MAX_FLOAT then
			if pos + 9 > size then
				buf, size = inflate(buf, pos + 9, size)
			end
			buffer.writeu8(buf, pos, DOUBLE)
			buffer.writef64(buf, pos+1, value)
			return buf, pos + 9, size
		end

		-- Ensures that the output WILL be the same as the input
		-- even if it results in a slower path
		if (vecX * value).x == value then
			if pos + 5 > size then
				buf, size = inflate(buf, pos + 5, size)
			end
			buffer.writeu8(buf, pos, FLOAT)
			buffer.writef32(buf, pos + 1, value)
			return buf, pos + 5, size
		end
		
		if pos + 9 > size then
			buf, size = inflate(buf, pos + 9, size)
		end
		buffer.writeu8(buf, pos, DOUBLE)
		buffer.writef64(buf, pos+1, value)
		return buf, pos + 9, size
	end

	local newSize = if MAX_BYTE >= value and value >= MIN_BYTE then
			2
		elseif MAX_CHAR >= value and value >= MIN_CHAR then
			3
		elseif MAX_THREE >= value and value >= MIN_THREE then
			4
		else
			5
	
	if pos + newSize > size then
		buf, size = inflate(buf, pos + newSize, size)
	end
	buffer.writeu8(buf, pos, ZERO + newSize)

	if newSize == 2 then
		buffer.writei8(buf, pos+1, value)
	elseif newSize == 3 then
		buffer.writei16(buf, pos+1, value)
	elseif newSize == 4 then
		buffer.writebits(buf, (pos + 1)*8, 24, value)
	else
		buffer.writei32(buf, pos+1, value)
	end
	return buf, pos + newSize, size
end

@native
local function numDeserializer(buf: buffer, pos: number): (number?, number)
	local id = buffer.readu8(buf, pos)

	if id == ZERO then
		return 0, pos + 1
	elseif id == ONE then
		return 1, pos + 1
	elseif id == NAN then
		return 0/0, pos + 1
	end
	
	if id > 99 then
		local cachedId = if id > 131 then
				(id - 132) * 256 + 32 + buffer.readu8(buf, pos + 1)
			else
				id - 99

		local cachedConstant: number? = READ[cachedId]
		if cachedConstant then
			return cachedConstant, 
				pos + (if cachedId > 32 then 2 else 1)
		end
	end

	if id == BYTE then
		return buffer.readi8(buf, pos + 1), pos + 2
	elseif id == CHAR then
		return buffer.readi16(buf, pos + 1), pos + 3
	elseif id == THREE_BYTE then
		local val = buffer.readbits(buf, (pos + 1)*8, 24)
		if val >= 2^23 then
			return (-2^24) + val, pos + 4
		end
		return val, pos + 4
	elseif id == INT then
		return buffer.readi32(buf, pos + 1), pos + 5
	elseif id == FLOAT then
		return buffer.readf32(buf, pos + 1), pos + 5
	elseif id == DOUBLE then
		return buffer.readf64(buf, pos + 1), pos + 9
	else
		return nil, pos + 1 -- data corruption
	end
end 

local Number = {
	Read = READ,
	Write = WRITE,

	serialize = numSerializer,
	deserialize = numDeserializer,
}

--[[
	Clears and replaces the read table
	
	@ Mainly used to reduce memory usage
]]--
function Number.resetRead()
	table.clear(READ)
end
--[[
	Clears and replaces the write table
	
	@ Mainly used to reduce memory usage
]]--
function Number.resetWrite()
	table.clear(WRITE)
end

return table.freeze(Number)
