--!optimize 2
--!strict
local inflate = require("./inflate")

local CUSTOM = 202
local NIL = 203

--[[
	The deserializer function for custom userdata.

	@param buf the buffer containing the serialized data
	@param pos the current position within the buffer

	@return value the userdata value serialized
	@return pos the new position within the buffer
]]
export type Reader = (buf: buffer, pos: number) -> (unknown, number)

--[[
	The serializer function for custom userdata.
	
	- If the position is unchanged when exiting the function, then
	 the userdata will be considered **unsupported**.
	  - Unsupported userdata is stored as a NIL userdata, which is
	   deserialized as a newproxy() and **not** a constant.

	@param value the userdata to serialize
	@param buf the buffer containing the serialized data
	@param pos the current position within the buffer
	@param size the size of the buffer

	@return buffer the buffer containing the serialized data
	@return pos the new position within the buffer
	@return size the new size of the buffer
]]
export type Writer = (
	value: unknown,
	buf: buffer,
	pos: number,
	size: number
) -> (buffer, number, number)

local Reader: Reader?
local Writer: Writer?

local function userSerializer(value: any, buf: buffer, pos: number, size: number)
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
end

--[[
	Produces a userdata from the buffer starting at the given position.

	@param buf buffer containing the userdata
	@param pos the starting position of the userdata

	@error buffer access out of bounds

	@return the userdata and the end of the userdata position + 1
]]
local function userDeserializer(buf: buffer, pos: number)
	local id = buffer.readu8(buf, pos)

	if Reader and id == CUSTOM then
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
end

--[[
	Returns the current custom userdata deserializer.

	Commonly used to cache the prior reader function when overwriting the
	 reader.  The prior reader is typically called whenever an unsupported
	 userdata is being handled.

	@return Reader the assigned custom userdata deserializer
]]
local function getReader()
	return Reader
end
--[[
	Sets the custom userdata deserializer.

	The reader function will be called whenever a custom userdata byte is
	 encountered in the serialized data.  It is common to check the first byte
	 to see if the userdata tag or type is supported, if it is not, the arguments
	 should be passed to older readers to handle.

	Note: The NIL userdata byte will not trigger the function call.

	@param Reader the new custom userdata deserializer

	@error Invalid type: When the reader is not a function
]]
local function setReader(reader: Reader)
	assert(
		type(reader) == "function",
		`Invalid type {type(reader)} (must be function)`
	)
	Reader = reader
end

--[[
	Returns the current custom userdata serializer.

	Commonly used to cache the prior writer function when overwriting the
	 writer.  The prior writer is typically called whenever an unsupported
	 userdata is being handled.

	@return Writer the assigned custom userdata serializer
]]
local function getWriter()
	return Writer
end
--[[
	Sets the custom userdata serializer.

	The writer function will always be called when serializing different
	 userdata.

	Note: By the returned position equaling the initial position, the
	 NIL userdata byte will be set instead of the custom userdata byte.

	@param Writer the new custom userdata serializer

	@error Invalid type: When the writer is not a function
]]
local function setWriter(writer: Writer)
	assert(
		type(writer) == "function",
		`Invalid type {type(writer)} (must be function)`
	)
	Writer = writer
end

local Userdata = {
	serialize = userSerializer,
	deserialize = userDeserializer,
	setReader = setReader,
	setWriter = setWriter,
	getReader = getReader,
	getWriter = getWriter,
}

return table.freeze(Userdata)
