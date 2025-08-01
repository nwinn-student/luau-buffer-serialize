--!optimize 2
local enumerator = require("./pointer/Enumerator")
type BufferData = enumerator.BufferData
type PositionData = enumerator.PositionData

local grow = enumerator.Methods.grow

enumerator = nil

local ZERO = 88
local ONE = 89
local BYTE = 90
local CHAR = 91
local THREE_BYTE = 92
local INT = 93
local FLOAT = 94
local DOUBLE = 95

local MIN_BYTE = -2^7
local MAX_BYTE = 2^7-1

local MIN_CHAR = -2^15
local MAX_CHAR = 2^15-1

local MIN_THREE = -2^23
local MAX_THREE = 2^23-1

local MIN_INT = -2^31
local MAX_INT = 2^31-1

local MAX_FLOAT = 2^127

local READ = {}
local WRITE = {} -- 1 to 1087

local FLOAT_BUFFER = buffer.create(4)

@native
local function numSerializer(value: number, data: BufferData)
	local buf = data.Data
	local pos = data.Position or 0

	if value == 0 then
		buf = grow(buf, data, 1)
		buffer.writeu8(buf, pos, ZERO)
		return
	elseif value == 1 then
		buf = grow(buf, data, 1)
		buffer.writeu8(buf, pos, ONE)
		return
	end

	local cachedConstant: number? = WRITE[value]
	if cachedConstant then
		local newSize = if cachedConstant <= 32 then 1
			else 2

		buf = grow(buf, data, newSize)

		if newSize == 1 then
			buffer.writeu8(buf, pos, cachedConstant + 99)
		else
			local constVal = cachedConstant - 64
			buffer.writeu8(buf, pos, 132 + (constVal // 256) )
			buffer.writeu8(buf, pos+1, constVal)
		end

		return
	end

	-- Floating points
	if value % 1 ~= 0 or value > MAX_INT or value < MIN_INT then

		if MAX_FLOAT < value or value < -MAX_FLOAT then
			buf = grow(buf, data, 9)
			buffer.writeu8(buf, pos, DOUBLE)
			buffer.writef64(buf, pos+1, value)
			return
		end

		-- Ensures that the output WILL be the same as the input
		-- even if it results in a slower path
		buffer.writef32(FLOAT_BUFFER, 0, value)
		if buffer.readf32(FLOAT_BUFFER, 0) - value == 0 then
			buf = grow(buf, data, 5)
			buffer.writeu8(buf, pos, FLOAT)
			buffer.writef32(buf, pos+1, value)
			return
		end

		buf = grow(buf, data, 9)
		buffer.writeu8(buf, pos, DOUBLE)
		buffer.writef64(buf, pos+1, value)
		return
	end

	local newSize = if MAX_BYTE >= value and value >= MIN_BYTE then 2
		elseif MAX_CHAR >= value and value >= MIN_CHAR then 3
		elseif MAX_THREE >= value and value >= MIN_THREE then 4
		else 5

	buf = grow(buf, data, newSize)
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
end

@native
local function numDeserializer(buf: buffer, data: PositionData)
	local pos = data.Position
	local id = buffer.readu8(buf, pos)

	if id == ZERO then
		data.Position += 1
		return 0
	elseif id == ONE then
		data.Position += 1
		return 1
	end

	local cachedId = if id > 131 then (id - 131) * 256 + 64
		else id - 99

	local cachedConstant = READ[cachedId]
	if cachedConstant then
		data.Position += if cachedId > 64 then 2 else 1
		return cachedConstant
	end

	if id == BYTE then
		data.Position += 2
		return buffer.readi8(buf, pos + 1)
	elseif id == CHAR then
		data.Position += 3
		return buffer.readi16(buf, pos + 1)
	elseif id == THREE_BYTE then
		data.Position += 4
		local val = buffer.readbits(buf, (pos + 1)*8, 24)
		if val >= 2^23 then
			return (-2^24) + val
		end
		return val
	elseif id == INT then
		data.Position += 5
		return buffer.readi32(buf, pos + 1)
	elseif id == FLOAT then
		data.Position += 5
		return buffer.readf32(buf, pos + 1)
	elseif id == DOUBLE then
		data.Position += 9
		return buffer.readf64(buf, pos + 1)
	else
		data.Position += 1
		return nil -- data corruption
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
	READ = {}
	Number.Read = READ
end
--[[
	Clears and replaces the write table
	
	@ Mainly used to reduce memory usage
]]--
function Number.resetWrite()
	table.clear(WRITE)
	WRITE = {}
	Number.Read = WRITE
end

return Number
