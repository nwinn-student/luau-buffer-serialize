--!optimize 2
--!strict
local inflate = require("./inflate")

local CUSTOM = 202
local NIL = 203

type Reader = (buf: buffer, pos: number) -> (unknown, number)
type Writer = (
	value: unknown,
	buf: buffer,
	pos: number,
	size: number
) -> (buffer, number, number)

local Reader: Reader?
local Writer: Writer?

local Userdata = {
	-- Need a way to set the approaches for serial and deserial

	serialize = function(value: any, buf: buffer, pos: number, size: number)
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
	setReader = function(reader: Reader)
		Reader = reader
	end,
	setWriter = function(writer: Writer)
		Writer = writer
	end,
}

return table.freeze(Userdata)
