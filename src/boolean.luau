--!optimize 2
--!strict
local inflate = require("./inflate")

--[[
	Serializes true/false values 
		into a single byte for storage
	Deserializes a buffer into a boolean value if applicable
]]
return table.freeze({
	serialize = function(value: boolean, buf: buffer, pos: number, size: number)
		if pos + 1 > size then
			buf, size = inflate(buf, pos + 1, size)
		end

		buffer.writeu8(buf, pos, if value then 1 else 2)
		return buf, pos + 1, size
	end,
	deserialize = function(buf: buffer, pos: number)
		local id = buffer.readu8(buf, pos)
		
		-- Can happen in the dictionary section of tables
		if id == 0 then
				error(`Failed to parse boolean at pos {pos}`)
		end
		
		return id == 1, pos + 1
	end,
})
