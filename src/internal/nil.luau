--!optimize 2
local enumerator = require("./pointer/Enumerator")

local inflate = enumerator.Methods.inflateBuffer

enumerator = nil

--[[
	Serializes nil values 
		into a single byte for storage
	Deserializes a buffer into a nil value if applicable
]]--
return {
	serialize = function(value: nil, buf: buffer, pos: number, size: number)
		if not buf then
			buf, size = buffer.create(1), 1
		elseif pos + 1 > size then
			buf, size = inflate(buf, pos + 1, size)
		end

		buffer.writeu8(buf, pos, 0)
		return buf, pos + 1, size
	end,
	deserialize = function(buf: buffer, pos: number): nil
		return nil, pos + 1
	end,
}
