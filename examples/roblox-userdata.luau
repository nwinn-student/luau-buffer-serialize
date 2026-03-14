--!optimize 2
local bufferSerial = require("@self/BufferSerializer")

--[[
	Specification for userdata:
	 [0] = BrickColor (2 + number bytes (3-5))
	 [1] = Color3 (2 + R / G / B bytes (5))
	 [2] = EnumItem (2 + number + number bytes (4-8))
	 [3] = CFrame (2 + vector + vector bytes (4-28))
	 [4] = Ray (2 + vector + vector bytes (4-28))
	 [5] = Instance (2 + tabSize bytes (16+?))
	 [6] = Enum (2 + number bytes (4-6)) (max number is char??)
	 [7] = UDim (2 + number + number (4-12)) (max number is float)
	 [8] = UDim2 (2 + number + number + number + number) (max number is float)
	 [9] = Vector2 (2 + number + number bytes (4-12)) (max number is float)
	 [10] = NumberSequence (2 + table (8+)) (table is { NumberSequenceKeypoint })
	 [11] = ColorSequence (2 + table (10+)) (table is { ColorSequenceKeypoint })
	 [12] = NumberRange (2 + number + number ())
	 [13] = Rect (2 + number + number + number + number (6-22)) (max number is float)
	 [14] = Font (2 + string + number + number (5-?)) (max number is char?)
	 [15] = NumberSequenceKeypoint (2 + number + number + number (5-?))
	 [16] = ColorSequenceKeypoint (2 + (R / G / B) + number (6-?))
	 -- add more as needed
]]--

local numberSerial = require("@BufferSerializer/number")
local stringSerial = require("@BufferSerializer/string")
local vectorSerial = require("@BufferSerializer/vector")
local tableSerial = require("@BufferSerializer/table")
local inflate = require("@BufferSerializer/inflate")

-- the only dependancy, Instances are not as simple to support
-- Location: https://github.com/Gem-API/Rose
local rose = require("./extern/rose")

local BRICKCOLOR = 0
local COLOR3 = 1
local ENUMITEM = 2
local CFRAME = 3
local RAY = 4
local INSTANCE = 5
local ENUM = 6
local UDIM = 7
local UDIM2 = 8
local VECTOR2 = 9 -- Vector3 is a vector, NOT a userdata
local NUMBER_SEQUENCE = 10
local COLOR_SEQUENCE = 11
local NUMBER_RANGE = 12
local RECT = 13
local FONT = 14
local NUMBER_SEQUENCE_KEYPOINT = 15
local COLOR_SEQUENCE_KEYPOINT = 16

@native
local function userdataWriter(value: any, buf: buffer, pos: number, size: number)
	local userType = typeof(value)
	if userType == "BrickColor" then
		buf, size = inflate(buf, pos + 2, size)
		buffer.writeu8(buf, pos, BRICKCOLOR)
		buf, pos, size = numberSerial.serialize(value.Number, buf, pos + 1, size)
	elseif userType == "Color3" then
		buf, size = inflate(buf, pos + 4, size)
		buffer.writeu8(buf, pos, COLOR3)
		buffer.writebits(buf, (pos + 1)*8, 24,
			tonumber(value:ToHex(), 16))
		pos += 4
	elseif userType == "EnumItem" then
		buf, size = inflate(buf, pos + 3, size)
		buffer.writeu8(buf, pos, ENUMITEM)
		buf, pos, size = numberSerial.serialize(
			table.find(Enum:GetEnums(), value.EnumType),
			buf, pos + 1, size
		)
		buf, pos, size = numberSerial.serialize(value.Value, buf, pos, size)
	elseif userType == "CFrame" then
		buf, size = inflate(buf, pos + 3, size)
		buffer.writeu8(buf, pos, CFRAME)
		buf, pos, size = vectorSerial.serialize(value.Position, buf, pos + 1, size)
		local x, y, z = (value :: CFrame):ToEulerAnglesXYZ()
		buf, pos, size = vectorSerial.serialize(
			vector.create(x, y, z),
			buf, pos, size
		)
	elseif userType == "Ray" then
		buf, size = inflate(buf, pos + 3, size)
		buffer.writeu8(buf, pos, RAY)
		buf, pos, size = vectorSerial.serialize(value.Origin, buf, pos + 1, size)
		buf, pos, size = vectorSerial.serialize(value.Direction, buf, pos, size)
	elseif userType == "Instance" then
		buf, size = inflate(buf, pos + 16, size)
		buffer.writeu8(buf, pos, INSTANCE)
		buf, pos, size = tableSerial.serialize(rose.serialize(value), buf, pos + 1, size)
	elseif userType == "Enum" then
		buf, size = inflate(buf, pos + 2, size)
		buffer.writeu8(buf, pos, ENUM)
		buf, pos, size = numberSerial.serialize(
			table.find(Enum:GetEnums(), value),
			buf, pos + 1, size
		)
	elseif userType == "UDim" then
		buf, size = inflate(buf, pos + 3, size)
		buffer.writeu8(buf, pos, UDIM)
		buf, pos, size = numberSerial.serialize(value.Scale, buf, pos + 1, size)
		buf, pos, size = numberSerial.serialize(value.Offset, buf, pos, size)
	elseif userType == "UDim2" then
		buf, size = inflate(buf, pos + 5, size)
		buffer.writeu8(buf, pos, UDIM2)
		buf, pos, size = numberSerial.serialize(value.X.Scale, buf, pos + 1, size)
		buf, pos, size = numberSerial.serialize(value.X.Offset, buf, pos, size)
		buf, pos, size = numberSerial.serialize(value.Y.Offset, buf, pos, size)
		buf, pos, size = numberSerial.serialize(value.Y.Offset, buf, pos, size)
	elseif userType == "Vector2" then
		buf, size = inflate(buf, pos + 3, size)
		buffer.writeu8(buf, pos, VECTOR2)
		buf, pos, size = numberSerial.serialize(value.X, buf, pos + 1, size)
		buf, pos, size = numberSerial.serialize(value.Y, buf, pos, size)
	elseif userType == "NumberSequence" then
		buf, size = inflate(buf, pos + 7, size)
		buffer.writeu8(buf, pos, NUMBER_SEQUENCE)
		buf, pos, size = tableSerial.serialize(value.Keypoints, buf, pos + 1, size)
	elseif userType == "NumberSequenceKeypoint" then
		buf, size = inflate(buf, pos + 4, size)
		buffer.writeu8(buf, pos, NUMBER_SEQUENCE_KEYPOINT)
		buf, pos, size = numberSerial.serialize(value.Time, buf, pos + 1, size)
		buf, pos, size = numberSerial.serialize(value.Value, buf, pos, size)
		buf, pos, size = numberSerial.serialize(value.Envelope, buf, pos, size)
	elseif userType == "ColorSequence" then
		buf, size = inflate(buf, pos + 9, size)
		buffer.writeu8(buf, pos, COLOR_SEQUENCE)
		buf, pos, size = tableSerial.serialize(value.Keypoints, buf, pos + 1, size)
	elseif userType == "ColorSequenceKeypoint" then
		buf, size = inflate(buf, pos + 5, size)
		buffer.writeu8(buf, pos, COLOR_SEQUENCE_KEYPOINT)
		buffer.writebits(buf, (pos + 1)*8, 24,
			tonumber(value.Value:ToHex(), 16))
		buf, pos, size = numberSerial.serialize(value.Time, buf, pos + 4, size)
	elseif userType == "NumberRange" then
		buf, size = inflate(buf, pos + 3, size)
		buffer.writeu8(buf, pos, NUMBER_RANGE)
		buf, pos, size = numberSerial.serialize(value.Min, buf, pos + 1, size)
		buf, pos, size = numberSerial.serialize(value.Max, buf, pos, size)
	elseif userType == "Rect" then
		buf, size = inflate(buf, pos + 5, size)
		buffer.writeu8(buf, pos, RECT)
		buf, pos, size = numberSerial.serialize(value.Min.X, buf, pos + 1, size)
		buf, pos, size = numberSerial.serialize(value.Min.Y, buf, pos, size)
		buf, pos, size = numberSerial.serialize(value.Max.X, buf, pos, size)
		buf, pos, size = numberSerial.serialize(value.Max.Y, buf, pos, size)
	elseif userType == "Font" then
		buf, size = inflate(buf, pos + 4, size)
		buffer.writeu8(buf, pos, FONT)
		buf, pos, size = stringSerial.serialize(value.Family, buf, pos + 1, size)
		buf, pos, size = numberSerial.serialize(value.Weight.Value, buf, pos, size)
		buf, pos, size = numberSerial.serialize(value.Style.Value, buf, pos, size)
	end
	return buf, pos, size
end

@native
local function userdataReader(buf: buffer, pos: number)
	local id = buffer.readu8(buf, pos)

	local obj

	if id == BRICKCOLOR then
		local valNum
		valNum, pos = numberSerial.deserialize(buf, pos + 1)
		if valNum then
			obj = BrickColor.new(valNum)
		end
	elseif id == COLOR3 then
		obj = Color3.fromRGB(
			buffer.readu8(buf, pos + 3),
			buffer.readu8(buf, pos + 2),
			buffer.readu8(buf, pos + 1)
		)
		pos += 4
	elseif id == ENUMITEM then
		local enumVal, valNum
		enumVal, pos = numberSerial.deserialize(buf, pos + 1)
		valNum, pos = numberSerial.deserialize(buf, pos)
		if enumVal and valNum then
			obj = Enum:GetEnums()[enumVal]
			if obj then
				obj = obj:FromValue(valNum)
			end
		end
	elseif id == CFRAME then
		local posVector, eulerVector
		posVector, pos = vectorSerial.deserialize(buf, pos + 1)
		eulerVector, pos = vectorSerial.deserialize(buf, pos)
		if posVector and eulerVector then
			obj = CFrame.fromEulerAngles(
				eulerVector.x,
				eulerVector.y,
				eulerVector.z
			) + posVector
		end
	elseif id == RAY then
		local orgVal, dirVal
		orgVal, pos = vectorSerial.deserialize(buf, pos + 1)
		dirVal, pos = vectorSerial.deserialize(buf, pos)
		if orgVal and dirVal then
			obj = Ray.new(orgVal, dirVal)
		end
	elseif id == INSTANCE then
		local roseVal
		roseVal, pos = tableSerial.deserialize(buf, pos + 1)
		if roseVal then
		-- the parent is LightService or nil!
			obj = rose.deserialize(roseVal)
		end
	elseif id == ENUM then
		local enumVal
		enumVal, pos = numberSerial.deserialize(buf, pos + 1)
		if enumVal then
			obj = Enum:GetEnums()[enumVal]
		end
	elseif id == UDIM then
		local scale, offset
		scale, pos = numberSerial.deserialize(buf, pos + 1)
		offset, pos = numberSerial.deserialize(buf, pos)

		obj = UDim.new(scale, offset)
	elseif id == UDIM2 then
		local xScale, xOffset, yScale, yOffset
		xScale, pos = numberSerial.deserialize(buf, pos + 1)
		xOffset, pos = numberSerial.deserialize(buf, pos)
		yScale, pos = numberSerial.deserialize(buf, pos)
		yOffset, pos = numberSerial.deserialize(buf, pos)

		obj = UDim2.new(xScale, xOffset, yScale, yOffset)
	elseif id == VECTOR2 then
		local x, y
		x, pos = numberSerial.deserialize(buf, pos + 1)
		y, pos = numberSerial.deserialize(buf, pos)

		obj = Vector2.new(x, y)
	elseif id == NUMBER_SEQUENCE then
		local keypoints
		keypoints, pos = tableSerial.deserialize(buf, pos + 1)

		obj = NumberSequence.new(keypoints)
	elseif id == NUMBER_SEQUENCE_KEYPOINT then
		local time, value, envelope
		time, pos = numberSerial.deserialize(buf, pos + 1)
		value, pos = numberSerial.deserialize(buf, pos)
		envelope, pos = numberSerial.deserialize(buf, pos)

		obj = NumberSequenceKeypoint.new(time, value, envelope)
	elseif id == COLOR_SEQUENCE then
		local keypoints
		keypoints, pos = tableSerial.deserialize(buf, pos + 1)

		obj = ColorSequence.new(keypoints)
	elseif id == COLOR_SEQUENCE_KEYPOINT then
		local color, time
		color = Color3.fromRGB(
			buffer.readu8(buf, pos + 3),
			buffer.readu8(buf, pos + 2),
			buffer.readu8(buf, pos + 1)
		)
		time, pos = numberSerial.deserialize(buf, pos + 4)

		obj = ColorSequenceKeypoint.new(time, color)
	elseif id == NUMBER_RANGE then
		local min, max
		min, pos = numberSerial.deserialize(buf, pos + 1)
		max, pos = numberSerial.deserialize(buf, pos)

		obj = NumberRange.new(min, max)
	elseif id == RECT then
		local minX, minY, maxX, maxY
		minX, pos = numberSerial.deserialize(buf, pos + 1)
		minY, pos = numberSerial.deserialize(buf, pos)
		maxX, pos = numberSerial.deserialize(buf, pos)
		maxY, pos = numberSerial.deserialize(buf, pos)

		obj = Rect.new(minX, minY, maxX, maxY)
	elseif id == FONT then
		local family, weightId, styleId
		family, pos = stringSerial.deserialize(buf, pos + 1)
		weightId, pos = numberSerial.deserialize(buf, pos)
		styleId, pos = numberSerial.deserialize(buf, pos)

		obj = Font.new(family, Enum.FontWeight:FromValue(weightId), Enum.FontStyle:FromValue(styleId))
	end

	return obj, pos
end

bufferSerial.supportUserdata({
	serialize = userdataWriter,
	deserialize = userdataReader,
})

return bufferSerial