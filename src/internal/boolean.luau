--!optimize 2
local enumerator = require("./pointer/Enumerator")
type BufferData = enumerator.BufferData
type PositionData = enumerator.PositionData

local grow = enumerator.Methods.grow

enumerator = nil

--[[
	Serializes true/false values 
		into a single byte for storage
	Deserializes a buffer into a boolean value if applicable
]]--
return {
	serialize = function(value: boolean, data: BufferData)
		local buf = data.Data
		local pos = data.Position or 0

		buf = grow(buf, data, 1)

		buffer.writeu8(buf, pos, if value then 1 else 2)
	end,
	deserialize = function(buf: buffer, data: PositionData)
		local value = buffer.readu8(buf, data.Position)
		data.Position += 1
		return value == 1
	end,
}
