--!optimize 2
--!strict
local inflate = require("./inflate")

local numSerializer = require("./number").serialize
local numDeserializer = require("./number").deserialize

local ZERO = 142
local ONE = 143
local X_AXIS = 144
local Y_AXIS = 145
local Z_AXIS = 146
local XY_AXIS = 147
local XZ_AXIS = 148
local YZ_AXIS = 149
local BYTE = 150
local CHAR = 151
local THREE_BYTE = 152
local FLOAT = 153
local NUMBER = 154
local SCALAR_NUMBER = 155

local builtinSerialConst = table.freeze({
	-- Used for serialization
	[vector.zero] = ZERO,
	[vector.one] = ONE,
	[vector.create(1, 0, 0)] = X_AXIS,
	[vector.create(0, 1, 0)] = Y_AXIS,
	[vector.create(0, 0, 1)] = Z_AXIS,
	[vector.create(1, 1, 0)] = XY_AXIS,
	[vector.create(1, 0, 1)] = XZ_AXIS,
	[vector.create(0, 1, 1)] = YZ_AXIS,
})
local builtinDeserialConst = table.freeze({
	-- Used for deserialization, indexing this is 30% faster
	-- than calling vector.create (vector.one/zero is 120% faster)
	[ONE] = vector.one,
	[X_AXIS] = vector.create(1, 0, 0),
	[Y_AXIS] = vector.create(0, 1, 0),
	[Z_AXIS] = vector.create(0, 0, 1),
	[XY_AXIS] = vector.create(1, 1, 0),
	[XZ_AXIS] = vector.create(1, 0, 1),
	[YZ_AXIS] = vector.create(0, 1, 1),
})

local MIN_BYTE = -2 ^ 7
local MAX_BYTE = 2 ^ 7 - 1

local MIN_CHAR = -2 ^ 15
local MAX_CHAR = 2 ^ 15 - 1

local MIN_THREE = -2 ^ 23
local MAX_THREE = 2 ^ 23 - 1

@native
local function getType(value: number): number
	return if value % 1 ~= 0
			or MAX_THREE < value
			or value < MIN_THREE
		then FLOAT
		elseif MAX_BYTE >= value and value >= MIN_BYTE then BYTE
		elseif MAX_CHAR >= value and value >= MIN_CHAR then CHAR
		else THREE_BYTE
end

@native
local function vecSerializer(
	value: vector,
	buf: buffer,
	pos: number,
	size: number
)
	local builtin: number? = builtinSerialConst[value]
	if builtin then
		if pos + 1 > size then
			buf, size = inflate(buf, pos + 1, size)
		end
		buffer.writeu8(buf, pos, builtin)
		return buf, pos + 1, size
	end

	-- now we check scalar
	local valueX = value.x
	local valueY = value.y
	local valueZ = value.z
	-- if nan (always better)
	local isNumber = valueX ~= valueX or valueY ~= valueY or valueZ ~= valueZ

	if not isNumber then
		-- best case we need to perform valX == valY twice and valX == 0 twice, can cache
		local isOneValue = valueX == valueY and valueY == valueZ
		local isXAxis = valueY == 0 and valueZ == 0
		local isYAxis = valueX == 0 and valueZ == 0
		local isZAxis = valueX == 0 and valueY == 0
		local isXYAxis = valueX == valueY and valueZ == 0
		local isXZAxis = valueX == valueZ and valueY == 0
		local isYZAxis = valueY == valueZ and valueX == 0

		if
			isOneValue
			or isXAxis
			or isYAxis
			or isZAxis
			or isXYAxis
			or isYZAxis
		then
			-- 3+ bytes
			if pos + 3 > size then
				buf, size = inflate(buf, pos + 3, size)
			end
			buffer.writeu8(buf, pos, SCALAR_NUMBER)

			local var = if isOneValue
				then ONE
				elseif isXAxis then X_AXIS
				elseif isYAxis then Y_AXIS
				elseif isZAxis then Z_AXIS
				elseif isXYAxis then XY_AXIS
				elseif isXZAxis then XZ_AXIS
				else YZ_AXIS

			buffer.writeu8(buf, pos + 1, var)

			local val = if isOneValue
					or isXAxis
					or isXYAxis
					or isXZAxis
				then valueX
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
		if isNumber and (typeX == FLOAT or typeY == FLOAT or typeZ == FLOAT) then
			-- fft = 15, ftt = 14
			-- so no floats
			typeX = FLOAT
			isNumber = false
		end
	end

	-- 4+ bytes (NOT intelligent, as a const byte will be more expensive)
	if isNumber then
		if pos + 4 > size then
			buf, size = inflate(buf, pos + 4, size)
		end
		buffer.writeu8(buf, pos, NUMBER)
		buf, pos, size = numSerializer(valueX, buf, pos + 1, size)
		buf, pos, size = numSerializer(valueY, buf, pos, size)
		return numSerializer(valueZ, buf, pos, size)
	end

	local newSize = 3 * ((typeX :: number) - YZ_AXIS) + 1
	-- 4, 7, 10, 13
	if pos + newSize > size then
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
		buffer.writebits(buf, (pos + 1) * 8, 24, valueX)
		buffer.writebits(buf, (pos + 4) * 8, 24, valueY)
		buffer.writebits(buf, (pos + 7) * 8, 24, valueZ)
	else
		buffer.writef32(buf, pos + 1, valueX)
		buffer.writef32(buf, pos + 5, valueY)
		buffer.writef32(buf, pos + 9, valueZ)
	end
	return buf, pos + newSize, size
end

--[[
	Produces a vector from the buffer starting at the given position.

	@param buf buffer containing the vector
	@param pos the starting position of the vector

	@error Failed to parse number
	@error Failed to parse built-in vector constant
	@error Failed to parse vector
	@error buffer access out of bounds

	@return the vector and the end vector position + 1
]]
@native
local function vecDeserializer(buf: buffer, pos: number)
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

	if id == SCALAR_NUMBER then
		local constId = buffer.readu8(buf, pos + 1)
		local vecVal = builtinDeserialConst[constId]
		if not vecVal then
			-- Must be ONE to YZ_AXIS
			error(
				`Failed to parse built-in vector constant using byte: {constId} at position {pos}`
			)
		end

		local numVal
		numVal, pos = numDeserializer(buf, pos + 2)
		return numVal * vecVal, pos
	elseif id == BYTE then
		return vector.create(
			buffer.readi8(buf, pos + 1),
			buffer.readi8(buf, pos + 2),
			buffer.readi8(buf, pos + 3)
		),
			pos + 4
	elseif id == CHAR then
		return vector.create(
			buffer.readi16(buf, pos + 1),
			buffer.readi16(buf, pos + 3),
			buffer.readi16(buf, pos + 5)
		),
			pos + 7
	elseif id == THREE_BYTE then
		local xVal = buffer.readbits(buf, (pos + 1) * 8, 24)
		local yVal = buffer.readbits(buf, (pos + 4) * 8, 24)
		local zVal = buffer.readbits(buf, (pos + 7) * 8, 24)

		return vector.create(
			xVal >= 2 ^ 23 and (-2 ^ 24) + xVal or xVal,
			yVal >= 2 ^ 23 and (-2 ^ 24) + yVal or yVal,
			zVal >= 2 ^ 23 and (-2 ^ 24) + zVal or zVal
		),
			pos + 10
	elseif id == FLOAT then
		return vector.create(
			buffer.readf32(buf, pos + 1),
			buffer.readf32(buf, pos + 5),
			buffer.readf32(buf, pos + 9)
		),
			pos + 13
	elseif id == NUMBER then
		local xVal, yVal, zVal
		xVal, pos = numDeserializer(buf, pos + 1)
		yVal, pos = numDeserializer(buf, pos)
		zVal, pos = numDeserializer(buf, pos)

		return vector.create(xVal, yVal, zVal), pos
	else
		error(`Failed to parse vector using byte: {id} at position {pos}`)
	end
end

local Vector = {
	serialize = vecSerializer,
	deserialize = vecDeserializer,
}

return table.freeze(Vector)
