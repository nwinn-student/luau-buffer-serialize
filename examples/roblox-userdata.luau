--!optimize 2
local bufferSerial = require("./BufferSerializer/Serialize")

--[[
	Specification for userdata:
		[0] = BrickColor (2 + number bytes (3-5))
		[1] = Color3 (2 + R / G / B bytes (5))
		[2] = EnumItem (2 + number + number bytes (4-8))
		[3] = CFrame (2 + vector + vector bytes (4-28))
		[4] = Ray (2 + vector + vector bytes (4-28))
		[5] = Instance (2 + tabSize bytes (16+?))
		[6] = Enum (2 + number bytes (4-6))
		-- add more as needed
]]--

local userdataSerial = require("./BufferSerializer/internal/userdata")
local numberSerial = require("./BufferSerializer/internal/number")
local vectorSerial = require("./BufferSerializer/internal/vector")
local tableSerial = require("./BufferSerializer/internal/table")
local inflate = require("./BufferSerializer/internal/pointer/Enumerator").Methods.inflateBuffer

-- the only dependancy, Instances are not as simple to support
local rose = require("./rose")

local BRICKCOLOR = 0
local COLOR3 = 1
local ENUMITEM = 2
local CFRAME = 3
local RAY = 4
local INSTANCE = 5
local ENUM = 6

@native
local function userdataWriter(value: any, buf: buffer, pos: number, size: number)
	local userType = typeof(value)
	if userType == "BrickColor" then
		if pos + 2 > size then
			buf, size = inflate(buf, pos + 2, size)
		end
		buffer.writeu8(buf, pos, BRICKCOLOR)
		buf, pos, size = numberSerial.serialize(value.Number, buf, pos + 1, size)
	elseif userType == "Color3" then
		if pos + 4 > size then
			buf, size = inflate(buf, pos + 4, size)
		end
		buffer.writeu8(buf, pos, COLOR3)
		buffer.writeu8(buf, pos + 1, value.R)
		buffer.writeu8(buf, pos + 2, value.G)
		buffer.writeu8(buf, pos + 3, value.B)
		pos += 4
	elseif userType == "EnumItem" then
		if pos + 3 > size then
			buf, size = inflate(buf, pos + 3, size)
		end
		buffer.writeu8(buf, pos, ENUMITEM)
		buf, pos, size = numberSerial.serialize(
			table.find(Enum:GetEnums(), value.EnumType),
			buf, pos + 1, size
		)
		buf, pos, size = numberSerial.serialize(value.Value, buf, pos, size)
	elseif userType == "CFrame" then
		if pos + 3 > size then
			buf, size = inflate(buf, pos + 3, size)
		end
		buffer.writeu8(buf, pos, CFRAME)
		buf, pos, size = vectorSerial.serialize(value.Position, buf, pos + 1, size)
		buf, pos, size = vectorSerial.serialize(
			vector.create(value:ToEulerAnglesXYZ()),
			buf, pos, size
		)
	elseif userType == "Ray" then
		if pos + 3 > size then
			buf, size = inflate(buf, pos + 3, size)
		end
		buffer.writeu8(buf, pos, RAY)
		buf, pos, size = vectorSerial.serialize(value.Origin, buf, pos + 1, size)
		buf, pos, size = vectorSerial.serialize(value.Direction, buf, pos, size)
	elseif userType == "Instance" then
		if pos + 16 > size then -- uncertain
			buf, size = inflate(buf, pos + 16, size)
		end
		buffer.writeu8(buf, pos, INSTANCE)
		buf, pos, size = tableSerial.serialize(rose.serialize(value), buf, pos + 1, size)
	elseif userType == "Enum" then
		if pos + 2 > size then
			buf, size = inflate(buf, pos + 2, size)
		end
		buffer.writeu8(buf, pos, ENUM)
		buf, pos, size = numberSerial.serialize(
			table.find(Enum:GetEnums(), value),
			buf, pos + 1, size
		)
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
		obj = Color3.new(
			buffer.readu8(buf, pos + 1),
			buffer.readu8(buf, pos + 2),
			buffer.readu8(buf, pos + 3)
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
	end
	
	return obj, pos
end

userdataSerial.setReader(userdataReader)
userdataSerial.setWriter(userdataWriter)

local testData = {
	Clothing = { -- ID, Color
		Shirt = {1, Color3.new(0, 0, 0)},
		Pants = {2, Color3.new(255, 200, 155)}
	},
	Location = CFrame.new(500, 500, 500)
}

local serData = bufferSerial.serialize(testData)

-- ...

local deserData = bufferSerial.deserialize(testData)
