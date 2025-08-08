--!optimize 2
local enumerator = require("./pointer/Enumerator")

local inflate = enumerator.Methods.inflateBuffer

enumerator = nil

local CUSTOM = 202
local NIL = 203

local READ = {}
local WRITE = {} -- 1 to 1039
local Reader
local Writer

local Userdata = {
	Read = READ,
	Write = WRITE,
	-- Need a way to set the approaches for serial and deserial

	serialize = function(value: any, buf: buffer, pos: number, size: number)

		local cachedConstant: number? = WRITE[value]
		if cachedConstant then
			local newSize = if cachedConstant <= 16 then 1
				else 2
			
			if not buf then
				buf, size = buffer.create(newSize), newSize
			elseif pos + newSize > size then
				buf, size = inflate(buf, pos + newSize, size)
			end

			if newSize == 1 then
				buffer.writeu8(buf, pos, cachedConstant + 203)
			else
				local constVal = cachedConstant - 64
				buffer.writeu8(buf, pos, 220 + (constVal // 256) )
				buffer.writeu8(buf, pos+1, constVal)
			end

			return buf, pos + newSize, size
		end

		if Writer then
			if not buf then
				buf, size = buffer.create(1), 1
			elseif pos + 1 > size then
				buf, size = inflate(buf, pos + 1, size)
			end
			buffer.writeu8(buf, pos, CUSTOM)
			local tempPos = pos + 1
			buf, pos, size = Writer(value, buf, pos + 1, size)
			if tempPos ~= pos then
				return buf, pos, size
			end
		end
		if not buf then
			buf, size = buffer.create(1), 1
		elseif pos + 1 > size then
			buf, size = inflate(buf, pos + 1, size)
		end
		buffer.writeu8(buf, pos, NIL)
		return buf, pos + 1, size
	end,
	deserialize = function(buf: buffer, pos: number)
		local id = buffer.readu8(buf, pos)

		local cachedId = if id > 219 then (id - 219) * 256 + 64
			else id - 203

		local cachedConstant = READ[cachedId]
		if cachedConstant then
			return cachedConstant, pos + (if cachedId > 64 then 2 else 1)
		end

		if Reader then
			return Reader(buf, pos + 1)
		end
		return nil, pos + 1
	end,
	setReader = function(reader: (buf: buffer, pos: number)->(unknown, number))
		Reader = reader
	end,
	setWriter = function(writer: (value: unknown, buf: buffer, pos: number, size: number)->(buffer, number, number))
		Writer = writer
	end
}

--[[
	Clears and replaces the read table
	
	@ Mainly used to reduce memory usage
]]--
function Userdata.resetRead()
	table.clear(READ)
	READ = {}
	Userdata.Read = READ
end
--[[
	Clears and replaces the write table
	
	@ Mainly used to reduce memory usage
]]--
function Userdata.resetWrite()
	table.clear(WRITE)
	WRITE = {}
	Userdata.Write = WRITE
end

return Userdata
