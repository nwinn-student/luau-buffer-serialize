--!optimize 2
local enumerator = require("./pointer/Enumerator")
local Number = require("./number")
type BufferData = enumerator.BufferData
type PositionData = enumerator.PositionData

local grow = enumerator.Methods.grow

enumerator = nil

local ZERO = 136
local ONE = 137
local X_AXIS = 138
local Y_AXIS = 139
local Z_AXIS = 140
local XY_AXIS = 141
local XZ_AXIS = 142
local YZ_AXIS = 143
local BYTE = 144
local CHAR = 145
local THREE_BYTE = 146
local FLOAT = 147
local NUMBER = 148
local SCALAR_NUMBER = 149

local READ = {}
local WRITE = {} -- 1 to 1087

local builtinConst = {
	[vector.zero] = ZERO,
	[vector.one] = ONE,
	[vector.create(1,0,0)] = X_AXIS,
	[vector.create(0,1,0)] = Y_AXIS,
	[vector.create(0,0,1)] = Z_AXIS,
	[vector.create(1,1,0)] = XY_AXIS,
	[vector.create(1,0,1)] = XZ_AXIS,
	[vector.create(0,1,1)] = YZ_AXIS
}

local MIN_BYTE = -2^7
local MAX_BYTE = 2^7-1

local MIN_CHAR = -2^15
local MAX_CHAR = 2^15-1

local MIN_THREE = -2^23
local MAX_THREE = 2^23-1

local function getType(value: number)
	if value % 1 ~= 0 or MAX_THREE < value or value < MIN_THREE then
		return FLOAT
	elseif MAX_BYTE >= value and value >= MIN_BYTE then
		return BYTE
	elseif MAX_CHAR >= value and value >= MIN_CHAR then
		return CHAR
	else
		return THREE_BYTE
	end
end

@native
local function vecSerializer(value: vector, data: BufferData)
	local buf = data.Data
	local pos = data.Position or 0

	local builtin: number? = builtinConst[value]
	if builtin then
		buf = grow(buf, data, 1)
		buffer.writeu8(buf, pos, builtin)
		return
	end

	local cachedConstant: number? = WRITE[value]
	if cachedConstant then
		local newSize = if cachedConstant <= 32 then 1
			else 2

		buf = grow(buf, data, newSize)

		if newSize == 1 then
			buffer.writeu8(buf, pos, cachedConstant + 157)
		else
			local constVal = cachedConstant - 64
			buffer.writeu8(buf, pos, 190 + (constVal // 256) )
			buffer.writeu8(buf, pos+1, constVal)
		end

		return
	end
	
	-- what if nan is in any?!
	-- i cannot force 1-2 bytes for vectors with nans it isn't possible
	-- we could check if the value == itself?
	
	-- now we check scalar
	local valueX = value.x
	local valueY = value.y
	local valueZ = value.z

	do
		local isOneValue = valueX == valueY and valueY == valueZ
		local isXAxis = valueY == 0 and valueZ == 0
		local isYAxis = valueX == 0 and valueZ == 0
		local isZAxis = valueX == 0 and valueY == 0
		local isXYAxis = valueX == valueY and valueZ == 0
		local isXZAxis = valueX == valueZ and valueY == 0
		local isYZAxis = valueY == valueZ and valueX == 0

		if isOneValue or isXAxis 
			or isYAxis or isZAxis
			or isXYAxis or isYZAxis
		then
			buf = grow(buf, data, 2)
			buffer.writeu8(buf, pos, SCALAR_NUMBER)

			local var = if isOneValue then ONE
				elseif isXAxis then X_AXIS
				elseif isYAxis then Y_AXIS
				elseif isZAxis then Z_AXIS
				elseif isXYAxis then XY_AXIS
				elseif isXZAxis then XZ_AXIS
				else YZ_AXIS

			buffer.writeu8(buf, pos+1, var)

			local val = if isOneValue or isXAxis or isXYAxis or isXZAxis then valueX
				elseif isYAxis or isYZAxis then valueY
				else valueZ
			Number.serialize(val, data)
			return
		end
	end

	-- now we check types
	local typeX = getType(valueX)
	local typeY = getType(valueY)
	local typeZ = getType(valueZ)

	local constX = Number.Write[valueX]
	local constY = Number.Write[valueY]
	local constZ = Number.Write[valueZ]

	local isNumber = valueX ~= valueX 
		or valueY ~= valueY 
		or valueZ ~= valueZ 
		or constX or constY or constZ

	if typeX ~= typeY or typeY ~= typeZ or isNumber then
		buf = grow(buf, data, 1)
		buffer.writeu8(buf, pos, NUMBER)
		Number.serialize(valueX, data)
		Number.serialize(valueY, data)
		Number.serialize(valueZ, data)
		return
	end

	local newSize = 3 * (typeX - 143) + 1
	buf = grow(buf, data, newSize) -- 4, 7, 10, 13
	buffer.writeu8(buf, pos, typeX)

	if typeX == BYTE then
		buffer.writei8(buf, pos + 1, valueX)
		buffer.writei8(buf, pos + 2, valueY)
		buffer.writei8(buf, pos + 3, valueZ)
	elseif typeX == CHAR then
		buffer.writei16(buf, pos + 1, valueX)
		buffer.writei16(buf, pos + 3, valueY)
		buffer.writei16(buf, pos + 5, valueZ)
	elseif typeX == THREE_BYTE then
		buffer.writebits(buf, (pos + 1)*8, 24, valueX)
		buffer.writebits(buf, (pos + 4)*8, 24, valueY)
		buffer.writebits(buf, (pos + 7)*8, 24, valueZ)
	else
		buffer.writef32(buf, pos + 1, valueX)
		buffer.writef32(buf, pos + 5, valueY)
		buffer.writef32(buf, pos + 9, valueZ)
	end
end

@native
local function vecDeserializer(buf: buffer, data: PositionData)
	local pos = data.Position
	local id = buffer.readu8(buf, pos)

	if id == ZERO then
		data.Position += 1
		return vector.zero
	elseif id == ONE then
		data.Position += 1
		return vector.one
	elseif id == X_AXIS then
		data.Position += 1
		return vector.create(1,0,0)
	elseif id == Y_AXIS then
		data.Position += 1
		return vector.create(0,1,0)
	elseif id == Z_AXIS then
		data.Position += 1
		return vector.create(0,0,1)
	elseif id == XY_AXIS then
		data.Position += 1
		return vector.create(1,1,0)
	elseif id == XZ_AXIS then
		data.Position += 1
		return vector.create(1,0,1)
	elseif id == YZ_AXIS then
		data.Position += 1
		return vector.create(0,1,1)
	end

	local cachedId = if id > 189 then (id - 189) * 256 + 64
		else id - 157

	local cachedConstant = READ[cachedId]
	if cachedConstant then
		data.Position += if cachedId > 64 then 2 else 1
		return cachedConstant
	end

	if id == SCALAR_NUMBER then
		data.Position += 1
		local vecVal = vecDeserializer(buf, data)
		local numVal = Number.deserialize(buf, data)
		if vecVal and numVal then
			return numVal * vecVal
		end
		return nil -- data corruption
	elseif id == BYTE then
		data.Position += 4
		return vector.create(
			buffer.readi8(buf, pos + 1), 
			buffer.readi8(buf, pos + 2),
			buffer.readi8(buf, pos + 3)
		)
	elseif id == CHAR then
		data.Position += 7
		return vector.create(
			buffer.readi16(buf, pos + 1), 
			buffer.readi16(buf, pos + 3),
			buffer.readi16(buf, pos + 5)
		)
	elseif id == THREE_BYTE then
		data.Position += 10
		local xVal = buffer.readbits(buf, (pos + 1)*8, 24)
		local yVal = buffer.readbits(buf, (pos + 4)*8, 24)
		local zVal = buffer.readbits(buf, (pos + 7)*8, 24)

		return vector.create(
			xVal >= 2^23 and (-2^24) + xVal or xVal, 
			yVal >= 2^23 and (-2^24) + yVal or yVal,
			zVal >= 2^23 and (-2^24) + zVal or zVal
		)
	elseif id == FLOAT then
		data.Position += 13
		return vector.create(
			buffer.readf32(buf, pos + 1), 
			buffer.readf32(buf, pos + 5),
			buffer.readf32(buf, pos + 9)
		)
	elseif id == NUMBER then
		data.Position += 1
		return vector.create(
			Number.deserialize(buf, data),
			Number.deserialize(buf, data),
			Number.deserialize(buf, data)
		)
	else
		data.Position += 1
		return nil -- data corrupted
	end
end

local Vector = {
	Read = READ,
	Write = WRITE,

	serialize = vecSerializer,
	deserialize = vecDeserializer,
}

--[[
	Clears and replaces the read table
	
	@ Mainly used to reduce memory usage
]]--
function Vector.resetRead()
	table.clear(READ)
	READ = {}
	Vector.Read = READ
end
--[[
	Clears and replaces the write table
	
	@ Mainly used to reduce memory usage
]]--
function Vector.resetWrite()
	table.clear(WRITE)
	WRITE = {}
	Vector.Read = WRITE
end

return Vector
