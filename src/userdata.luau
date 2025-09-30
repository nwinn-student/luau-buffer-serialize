--!optimize 2
--!strict
local inflate = require("./inflate")

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
			local newSize = if cachedConstant <= 16 then
					1
				else
					2
			
			if pos + newSize > size then
				buf, size = inflate(buf, pos + newSize, size)
			end

			if newSize == 1 then
				buffer.writeu8(buf, pos, cachedConstant + 203)
			else
				local constVal = cachedConstant - 16
				buffer.writeu8(buf, pos, 220 + (constVal // 256) )
				buffer.writeu8(buf, pos+1, constVal)
			end

			return buf, pos + newSize, size
		end

		if Writer then
			if pos + 1 > size then
				buf, size = inflate(buf, pos + 1, size)
			end
			buffer.writeu8(buf, pos, CUSTOM)
			local tempPos = pos + 1
			buf, pos, size = Writer(value, buf, pos + 1, size)
			if tempPos ~= pos then
				return buf, pos, size
			end
		end
		if pos + 1 > size then
			buf, size = inflate(buf, pos + 1, size)
		end
		buffer.writeu8(buf, pos, NIL)
		return buf, pos + 1, size
	end,
	deserialize = function(buf: buffer, pos: number)
		local id = buffer.readu8(buf, pos)

		if id > 203 then
				local cachedId = if id > 219 then
					(id - 220) * 256 + 16 + buffer.readu8(buf, pos + 1)
				else
					id - 203

			local cachedConstant = READ[cachedId]
			if cachedConstant then
				return cachedConstant, 
					pos + (if cachedId > 16 then 2 else 1)
			end
		end

		if Reader then
			local obj
			obj, pos = Reader(buf, pos + 1)
			if obj == nil then
				-- We cannot return nil or it will corrupt
				return newproxy(), pos + 1
			end
			return obj, pos
		end
		-- We cannot return nil or it will corrupt
		return newproxy(), pos + 1
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
end
--[[
	Clears and replaces the write table
	
	@ Mainly used to reduce memory usage
]]--
function Userdata.resetWrite()
	table.clear(WRITE)
end

return table.freeze(Userdata)
