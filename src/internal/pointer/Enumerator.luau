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
function inflateBuffer(data: BufferData)
	local currPos = data.Position
	local currSize = data.Size
	local oldSize = data.Size
	local currBuf = data.Data

	while currPos > currSize do
		currSize *= 2
	end
	if currSize ~= oldSize then
		local temp = buffer.create(currSize)
		buffer.copy(temp, 0, currBuf) -- , 0, currPos
		data.Data = temp
		data.Size = currSize -- ??
	end
end
methods.inflateBuffer = inflateBuffer

--[[
	Alters the first byte to be the specified value.
	
	@param buf the buffer
	@param variant the type of value being serialized
	
	@return the buffer with the first byte set to the value
]]--
@native
function methods.grow(buf: buffer, data: BufferData, size: number, value: number)
	if not buf then
		buf = buffer.create(size)
		data.Data = buf
		data.Size = size
	end
	data.Position += size
	if data.Position > data.Size then
		inflateBuffer(data)
	end
	return data.Data
end

methods.trim = function(data: BufferData)
	local size = data.Size
	local pos = data.Position
	local buf = data.Data

	if size == pos then
		return buf
	end
	local newBuf = buffer.create(pos)
	buffer.copy(newBuf, 0, buf, 0, pos)
	data.Data = newBuf
	return newBuf
end

enumerator.Methods = methods
return enumerator
