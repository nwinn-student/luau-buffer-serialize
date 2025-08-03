--!optimize 2
local enumerator = {
	-- For Serialize
	[0] = 'nil',
	'boolean',
	'buffer',
	'string',
	'number',
	'vector',
	'table',
	'userdata'
}

local methods = {}

type Variant = number

export type BufferData = {
	Position: Variant,
	Data: buffer,
	Size: Variant
}
export type PositionData = {Position: Variant}

--[[
	Inflates the buffer size to be at least the new position.
]]--
@native
function inflateBuffer(data: buffer, pos: number, size: number)
	local oldSize = buffer.len(data)
	local currSize = oldSize
	
	local minSize = pos + size

	while minSize > currSize do
		currSize *= 2
	end
	
	if currSize == oldSize then
		return data
	end
	local temp = buffer.create(currSize)
	buffer.copy(temp, 0, data, 0, pos)
	return temp
end
methods.inflateBuffer = inflateBuffer

--[[
	Alters the first byte to be the specified value.
	
	@param buf the buffer
	@param variant the type of value being serialized
	
	@return the buffer with the first byte set to the value
]]--
@native
function methods.grow(data: buffer, pos: number, size: number)
	if not data then
		return buffer.create(size)
	end
	return inflateBuffer(data, pos, size)
end

methods.trim = function(data: buffer, pos: number)
	if buffer.len(data) == pos then
		return data
	end
	local newBuf = buffer.create(pos)
	buffer.copy(newBuf, 0, data, 0, pos)
	return newBuf
end

enumerator.Methods = methods
return enumerator
