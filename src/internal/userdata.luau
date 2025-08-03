--!optimize 2
local enumerator = require("./pointer/Enumerator")
type BufferData = enumerator.BufferData
type PositionData = enumerator.PositionData

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

	serialize = function(value: unknown, data: BufferData)
		local buf = data.Data
		local pos = data.Position or 0

		local cachedConstant: number? = WRITE[value]
		if cachedConstant then
			local newSize = if cachedConstant <= 16 then 1
				else 2

			buf = grow(buf, data, newSize)

			if newSize == 1 then
				buffer.writeu8(buf, pos, cachedConstant + 203)
			else
				local constVal = cachedConstant - 64
				buffer.writeu8(buf, pos, 220 + (constVal // 256) )
				buffer.writeu8(buf, pos+1, constVal)
			end

			return
		end
		
		-- wrong!!!
		if Writer then
			buf = grow(buf, data, 1)
			buffer.writeu8(buf, pos, CUSTOM)
			Writer(value, data)
			if pos+1 ~= data.Position then
				return
			end
		end
		buf = grow(buf, data, 1)
		buffer.writeu8(buf, pos, NIL)
	end,
	deserialize = function(buf: buffer, data: PositionData)
		local pos = data.Position
		local id = buffer.readu8(buf, pos)
		
		local cachedId = if id > 219 then (id - 219) * 256 + 64
			else id - 203

		local cachedConstant = READ[cachedId]
		if cachedConstant then
			data.Position += if cachedId > 64 then 2 else 1
			return cachedConstant
		end
		
		data.Position += 1
		
		-- wrong!!!
		if Reader then
			return Reader(buf, data)
		end
		return nil
	end,
	setReader = function(reader: (buf: buffer, data: PositionData)->(unknown))
		Reader = reader
	end,
	setWriter = function(writer: (value: unknown, data: BufferData)->())
		Writer = writer
	end
}
