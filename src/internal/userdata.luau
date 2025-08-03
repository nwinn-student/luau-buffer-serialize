--!optimize 2
local enumerator = require("./pointer/Enumerator")

local grow = enumerator.Methods.grow

enumerator = nil

local CUSTOM = 202
local NIL = 203

local READ = {}
local WRITE = {} -- 1 to 1087
local Reader
local Writer

return {
	Read = READ,
	Write = WRITE,
	-- Need a way to set the approaches for serial and deserial

	serialize = function(value: unknown, buf: buffer, pos: number)

		local cachedConstant: number? = WRITE[value]
		if cachedConstant then
			local newSize = if cachedConstant <= 16 then 1
				else 2

			buf = grow(buf, pos, newSize)

			if newSize == 1 then
				buffer.writeu8(buf, pos, cachedConstant + 203)
			else
				local constVal = cachedConstant - 64
				buffer.writeu8(buf, pos, 220 + (constVal // 256) )
				buffer.writeu8(buf, pos+1, constVal)
			end

			return buf, pos + newSize
		end
		
		-- wrong!!!
		if Writer then
			buf = grow(buf, pos, 1)
			buffer.writeu8(buf, pos, CUSTOM)
			local tempPos = pos + 1
			buf, pos = Writer(value, buf, pos + 1)
			if tempPos ~= pos then
				return buf, pos
			end
		end
		buf = grow(buf, pos, 1)
		buffer.writeu8(buf, pos, NIL)
		return buf, pos + 1
	end,
	deserialize = function(buf: buffer, pos: number)
		local id = buffer.readu8(buf, pos)
		
		local cachedId = if id > 219 then (id - 219) * 256 + 64
			else id - 203

		local cachedConstant = READ[cachedId]
		if cachedConstant then
			return cachedConstant, pos + (if cachedId > 64 then 2 else 1)
		end
		
		
		-- wrong!!!
		if Reader then
			return Reader(buf, pos + 1)
		end
		return nil, pos + 1
	end,
	setReader = function(reader: (buf: buffer, data: PositionData)->(unknown))
		Reader = reader
	end,
	setWriter = function(writer: (value: unknown, data: BufferData)->())
		Writer = writer
	end
}
