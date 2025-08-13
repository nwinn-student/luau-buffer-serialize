local bufferSerial = require("./BufferSerializer/Serialize")
local userdataSerial = require("./BufferSerializer/internal/userdata")
local vectorSerial = require("./BufferSerializer/internal/vector")
local inflate = require("./BufferSerializer/internal/pointer/Enumerator").Methods.inflateBuffer

local CFRAME = 5 -- assuming you want to have other userdata supported

--[[

There are multiple approaches of varying accuracy depending on how cheap 
CFrames must be.  The below approach is incredibly accurate, however for 
perfect accuracy numbers must be used in place of CFrame:ToEulerAnglesXYZ.

Should solely the position or solely the orientation be important, only 
serialize those sections.  Should a section's accuracy not be as important, 
the values can be pre-processed to ensure a cheaper result.

]]--

local function cframeWriter(value: CFrame, buf: buffer, pos: number, size: number)
	local typeV = typeof(value)
	if typeV == "CFrame" then
		buf, size = inflate(buf, pos + 1, size)
		buffer.writeu8(buf, pos, CFRAME)
		buf, pos, size = vectorSerial.serialize(value.Position, buf, pos + 1, size)
		buf, pos, size = vectorSerial.serialize(vector.create(value:ToEulerAnglesXYZ()), buf, pos, size)
	end
	return buf, pos, size
end

local function cframeReader(buf: buffer, pos: number): (any, number)
	local id = buffer.readu8(buf, pos)
	if id == CFRAME then
		local posVector, eulerVector
		posVector, pos = vectorSerial.deserialize(buf, pos + 1)
		eulerVector, pos = vectorSerial.deserialize(buf, pos)
		return CFrame.fromEulerAngles(
			eulerVector.x, 
			eulerVector.y, 
			eulerVector.z
		) + posVector, pos
	end
	return nil, pos
end

userdataSerial.setReader(cframeReader)
userdataSerial.setWriter(cframeWriter)

local data = CFrame.new()

local serData = bufferSerial.serialize(data)

-- ...

local deserData = bufferSerial.deserialize(serData)