--!optimize 2
local enumerator = require("./pointer/Enumerator")

local inflate = enumerator.Methods.inflateBuffer

enumerator = nil

--[[
	Serializes true/false values 
		into a single byte for storage
	Deserializes a buffer into a boolean value if applicable
]]--
return {
	serialize = function(value: boolean, buf: buffer, pos: number, size: number)
		if not buf then
			buf, size = buffer.create(1), 1
		elseif pos + 1 > size then
			buf, size = inflate(buf, pos + 1, size)
		end

		buffer.writeu8(buf, pos, if value then 1 else 2)
		return buf, pos + 1, size
	end,
	deserialize = function(buf: buffer, pos: number)
		return buffer.readu8(buf, pos) == 1, pos + 1
	end,
}
