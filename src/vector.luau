--!optimize 2
--!strict
local inflate = require("./inflate")

local numSerializer = require("./number").serialize
local numDeserializer = require("./number").deserialize
local numWrite = require("./number").Write

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
local WRITE = {} -- 1 to 1055

local builtinSerialConst = {
	-- Used for serialization
	[vector.zero] = ZERO,
	[vector.one] = ONE,
	[vector.create(1,0,0)] = X_AXIS,
	[vector.create(0,1,0)] = Y_AXIS,
	[vector.create(0,0,1)] = Z_AXIS,
	[vector.create(1,1,0)] = XY_AXIS,
	[vector.create(1,0,1)] = XZ_AXIS,
	[vector.create(0,1,1)] = YZ_AXIS
}
local builtinDeserialConst = {
	-- Used for deserialization, indexing this is 30% faster
	-- than calling vector.create (vector.one/zero is 120% faster)
	[ONE] = vector.one,
	[X_AXIS] = vector.create(1,0,0),
	[Y_AXIS] = vector.create(0,1,0),
	[Z_AXIS] = vector.create(0,0,1),
	[XY_AXIS] = vector.create(1,1,0),
	[XZ_AXIS] = vector.create(1,0,1),
	[YZ_AXIS] = vector.create(0,1,1)
}

local MIN_BYTE = -2^7
local MAX_BYTE = 2^7-1

local MIN_CHAR = -2^15
local MAX_CHAR = 2^15-1

local MIN_THREE = -2^23
local MAX_THREE = 2^23-1

@native
local function getType(value: number): number
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
local function vecSerializer(value: vector, buf: buffer, pos: number, size: number)

	local builtin: number? = builtinSerialConst[value]
	if builtin then
		if not buf then
			buf, size = buffer.create(1), 1
		elseif pos + 1 > size then
			buf, size = inflate(buf, pos + 1, size)
		end
		buffer.writeu8(buf, pos, builtin)
		return buf, pos + 1, size
	end

	local cachedConstant: number? = WRITE[value]
	if cachedConstant then
		local newSize = if cachedConstant <= 32 then 1
			else 2
		
		if not buf then
			buf, size = buffer.create(newSize), newSize
		elseif pos + newSize > size then
			buf, size = inflate(buf, pos + newSize, size)
		end

		if newSize == 1 then
			buffer.writeu8(buf, pos, cachedConstant + 157)
		else
			local constVal = cachedConstant - 64
			buffer.writeu8(buf, pos, 190 + (constVal // 256) )
			buffer.writeu8(buf, pos+1, constVal)
		end

		return buf, pos + newSize, size
	end

	-- now we check scalar
	local valueX = value.x
	local valueY = value.y
	local valueZ = value.z
	-- if nan (always better)
	local isNumber = valueX ~= valueX 
		or valueY ~= valueY 
		or valueZ ~= valueZ

	if not isNumber then
		-- best case we need to perform valX == valY twice and valX == 0 twice, can cache
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
			-- 3+ bytes
			if not buf then
				buf, size = buffer.create(3), 3
			elseif pos + 3 > size then
				buf, size = inflate(buf, pos + 3, size)
			end
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
			return numSerializer(val, buf, pos + 2, size)
		end
	end

	-- now we check types
	local typeX, typeY, typeZ
	
	-- if num type differs
	if not isNumber then
		typeX = getType(valueX)
		typeY = getType(valueY)
		isNumber = typeX ~= typeY
	end
	if not isNumber then
		typeZ = getType(valueZ)
		isNumber = typeY ~= typeZ 
	end
	if not isNumber and typeX ~= BYTE then
		-- if num is a constant and all types aren't byte
		-- char/tryte COULD be cheaper (1 + 2 (const) + 5 (float) + 5 (float) is worst case)
		-- the checks are VERY expensive (from a line perspective) though
		isNumber = (
			numWrite[valueX] or numWrite[valueY] or numWrite[valueZ]
		)
	end
	
	-- 4+ bytes (NOT intelligent, as a const byte will be more expensive)
	if isNumber then
		if not buf then
			buf, size = buffer.create(4), 4
		elseif pos + 4 > size then
			buf, size = inflate(buf, pos + 4, size)
		end
		buffer.writeu8(buf, pos, NUMBER)
		buf, pos, size = numSerializer(valueX, buf, pos + 1, size)
		buf, pos, size = numSerializer(valueY, buf, pos, size)
		return numSerializer(valueZ, buf, pos, size)
	end

	local newSize = 3 * ((typeX :: number) - 143) + 1
	-- 4, 7, 10, 13
	if not buf then
		buf, size = buffer.create(newSize), newSize
	elseif pos + newSize > size then
		buf, size = inflate(buf, pos + newSize, size)
	end
	buffer.writeu8(buf, pos, typeX :: number)

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
	return buf, pos + newSize, size
end

@native
local function vecDeserializer(buf: buffer, pos: number): (vector?, number)
	local id = buffer.readu8(buf, pos)

	if id == ZERO then
		return vector.zero, pos + 1
	elseif id == ONE then
		return vector.one, pos + 1
	elseif id == X_AXIS then
		return builtinDeserialConst[X_AXIS], pos + 1
	elseif id == Y_AXIS then
		return builtinDeserialConst[Y_AXIS], pos + 1
	elseif id == Z_AXIS then
		return builtinDeserialConst[Z_AXIS], pos + 1
	elseif id == XY_AXIS then
		return builtinDeserialConst[XY_AXIS], pos + 1
	elseif id == XZ_AXIS then
		return builtinDeserialConst[XZ_AXIS], pos + 1
	elseif id == YZ_AXIS then
		return builtinDeserialConst[YZ_AXIS], pos + 1
	end

	local cachedId = if id > 189 then (id - 189) * 256 + 64
		else id - 157

	local cachedConstant = READ[cachedId]
	if cachedConstant then
		return cachedConstant, pos + (if cachedId > 64 then 2 else 1)
	end

	if id == SCALAR_NUMBER then
		local vecVal = builtinDeserialConst[buffer.readu8(buf, pos + 1)]
		local numVal
		numVal, pos = numDeserializer(buf, pos + 2)
		if vecVal and numVal then
			return numVal * vecVal, pos
		end
		return nil, pos + 1 -- data corruption
	elseif id == BYTE then
		return vector.create(
			buffer.readi8(buf, pos + 1), 
			buffer.readi8(buf, pos + 2),
			buffer.readi8(buf, pos + 3)
		), pos + 4
	elseif id == CHAR then
		return vector.create(
			buffer.readi16(buf, pos + 1), 
			buffer.readi16(buf, pos + 3),
			buffer.readi16(buf, pos + 5)
		), pos + 7
	elseif id == THREE_BYTE then
		local xVal = buffer.readbits(buf, (pos + 1)*8, 24)
		local yVal = buffer.readbits(buf, (pos + 4)*8, 24)
		local zVal = buffer.readbits(buf, (pos + 7)*8, 24)

		return vector.create(
			xVal >= 2^23 and (-2^24) + xVal or xVal, 
			yVal >= 2^23 and (-2^24) + yVal or yVal,
			zVal >= 2^23 and (-2^24) + zVal or zVal
		), pos + 10
	elseif id == FLOAT then
		return vector.create(
			buffer.readf32(buf, pos + 1), 
			buffer.readf32(buf, pos + 5),
			buffer.readf32(buf, pos + 9)
		), pos + 13
	elseif id == NUMBER then
		local xVal, yVal, zVal
		xVal, pos = numDeserializer(buf, pos + 1)
		yVal, pos = numDeserializer(buf, pos)
		zVal, pos = numDeserializer(buf, pos)
		
		if xVal and yVal and zVal then
			return vector.create(xVal, yVal, zVal), pos
		end
		-- fill with 0's instead?
		return nil, pos + 1 -- data corrupted
	else
		return nil, pos + 1 -- data corrupted
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
	Vector.Write = WRITE
end

return Vector
