--!optimize 2
local enumerator = require("./pointer/Enumerator")

local grow = enumerator.Methods.grow

enumerator = nil

--[[
	Serializes nil values 
		into a single byte for storage
	Deserializes a buffer into a nil value if applicable
]]--
return {
	serialize = function(value: nil, buf: buffer, pos: number)
		buf = grow(buf, pos, 1)

		buffer.writeu8(buf, pos, 0)
		return buf, pos + 1
	end,
	deserialize = function(buf: buffer, pos: number): nil
		return nil, pos + 1
	end,
}
