local bufferSerial = require("./BufferSerializer/Serialize")

-- not done yet!!
local function cframeWriter(value: unknown, buf: buffer, pos: number, size: number)
	
	
	return buf, pos, size
end

local function cframeReader(buf: buffer, pos: number)
	
	return CFrame.new(), pos
end

bufferSerial.setUserdata(cframeReader, cframeWriter)

local data = CFrame.new()

local serData = bufferSerial.serialize(data)

-- ...

local deserData = bufferSerial.deserialize(serData)