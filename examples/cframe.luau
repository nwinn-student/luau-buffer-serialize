local bufferSerial = require("./BufferSerializer/Serialize")
local userdataSerial = require("./BufferSerializer/internal/userdata")
local inflate = require("./BufferSerializer/internal/pointer/Enumerator").Methods.inflateBuffer

local CFRAME = 5 -- assuming you want to have other userdata supported

--[[

The provided approach ONLY stores the positional data of the CFrame, a lazy approach

]]--

-- Better approach
-- https://devforum.roblox.com/t/how-to-efficiently-store-cframe-values-in-datastores/2909067/14
local function cframeWriter(value: unknown, buf: buffer, pos: number, size: number)
	local typeV = typeof(value)
	if typeV == "CFrame" then
		buf, size = inflate(buf, pos + 13, size)
		buffer.writeu8(buf, pos, CFRAME)
		buffer.writef32(buf, pos + 1, value.X)
		buffer.writef32(buf, pos + 5, value.Y)
		buffer.writef32(buf, pos + 9, value.Z)
		
		return buf, pos + 13, size
	end
end

local function cframeReader(buf: buffer, pos: number)
	local id = buffer.readu8(buf, pos)
	if id == CFRAME then
		return CFrame.new(
			buffer.readf32(buf, pos + 1),
			buffer.readf32(buf, pos + 5),
			buffer.readf32(buf, pos + 9)
		), pos + 13
	end
end

userdataSerial.setReader(cframeReader)
userdataSerial.setWriter(cframeWriter)

local data = CFrame.new()

local serData = bufferSerial.serialize(data)

-- ...

local deserData = bufferSerial.deserialize(serData)