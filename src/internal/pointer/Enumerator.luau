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

--[[
	Inflates the buffer size to be at least the new position.
]]--
@native
function inflateBuffer(data: buffer, pos: number, size: number, oldSize: number)
	local currSize = oldSize
	
	local minSize = pos + size

	while minSize > currSize do
		currSize *= 2
	end
	
	if currSize == oldSize then
		return data
	end
	local temp = buffer.create(currSize)
	buffer.copy(temp, 0, data)
	return temp
end
methods.inflateBuffer = inflateBuffer


local tempBuf = nil
local tempBufLen = 0

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
	local bufLen
	if data == tempBuf then
		bufLen = tempBufLen
	else
		tempBuf = data
		tempBufLen = buffer.len(data) -- this is much slower than data.Size
		bufLen = tempBufLen
	end
	if pos + size > bufLen then
		return inflateBuffer(data, pos, size, bufLen)
	end
	return data
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
