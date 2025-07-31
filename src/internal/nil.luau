--!optimize 2
local enumerator = require("./pointer/Enumerator")
type BufferData = enumerator.BufferData
type PositionData = enumerator.PositionData

local grow = enumerator.Methods.grow

enumerator = nil

--[[
	Serializes nil values 
		into a single byte for storage
	Deserializes a buffer into a nil value if applicable
]]--
return {
	serialize = function(value: nil, data: BufferData)
		local buf = data.Data
		local pos = data.Position or 0

		buf = grow(buf, data, 1)

		buffer.writeu8(buf, pos, 0)
	end,
	deserialize = function(buf: buffer, data: PositionData): nil
		data.Position += 1
		return nil
	end,
}
