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
function inflateBuffer(data: buffer, minSize: number, oldSize: number)

	while minSize > oldSize do
		oldSize *= 2
	end

	local temp = buffer.create(oldSize)
	buffer.copy(temp, 0, data)
	return temp, oldSize
end
methods.inflateBuffer = inflateBuffer


methods.trim = function(data: buffer, pos: number, size: number)
	if size == pos then
		return data
	end
	local newBuf = buffer.create(pos)
	buffer.copy(newBuf, 0, data, 0, pos)
	return newBuf
end

enumerator.Methods = methods
return enumerator
