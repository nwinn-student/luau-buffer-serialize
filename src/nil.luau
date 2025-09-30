--!optimize 2
--!strict
local inflate = require("./inflate")

--[[
	Serializes nil values 
		into a single byte for storage
	Deserializes a buffer into a nil value if applicable
]]--
return table.freeze({
	serialize = function(value: nil, buf: buffer, pos: number, size: number)
		if pos + 1 > size then
			buf, size = inflate(buf, pos + 1, size)
		end

		buffer.writeu8(buf, pos, 0)
		return buf, pos + 1, size
	end,
	deserialize = function(buf: buffer, pos: number)
		return nil, pos + 1
	end,
})
