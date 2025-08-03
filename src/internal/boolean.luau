--!optimize 2
local enumerator = require("./pointer/Enumerator")

local grow = enumerator.Methods.grow

enumerator = nil

--[[
	Serializes true/false values 
		into a single byte for storage
	Deserializes a buffer into a boolean value if applicable
]]--
return {
	serialize = function(value: boolean, buf: buffer, pos: number)
		buf = grow(buf, pos, 1)

		buffer.writeu8(buf, pos, if value then 1 else 2)
		return buf, pos + 1
	end,
	deserialize = function(buf: buffer, pos: number)
		return buffer.readu8(buf, pos) == 1, pos + 1
	end,
}
