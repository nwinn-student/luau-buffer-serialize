--!optimize 2
do
	-- For runtimes that cache the requires
	require("@self/table")
end

@native
local function trim(data: buffer, pos: number, size: number)
	if size == pos then
		return data
	end
	local newBuf = buffer.create(pos)
	buffer.copy(newBuf, 0, data, 0, pos)
	return newBuf
end

local enumerator = {
	[0] = 'nil',
	'boolean',
	'buffer',
	'string',
	'number',
	'vector',
	'table',
	'userdata'
}

local BufferSerializer = {}
local modules = {}

--[[
	Returns the value as a buffer
	
	@param value the value to serialize
	
	@return a buffer representing the serialized value
]]--
BufferSerializer.serialize = function(value: any): buffer
	local typeValue = type(value)
	if typeValue == "function" or typeValue == "thread" then
		typeValue = "nil"
	end

	local serial = modules[typeValue]
	if not serial then
		serial = require(`@self/{typeValue}`).serialize
		modules[typeValue] = serial
	end
	return trim(serial(value, nil, 0, 0))
end

--[[
	
	
	@param value
	
	@return 
]]--
BufferSerializer.deserialize = function(value: buffer): any
	local pointer = buffer.readu8(value, 0)
	if pointer == 0 then return nil end

	if pointer > 1 then
		pointer = if pointer <= 2 then
			1 -- boolean
			elseif pointer <= 8 then
			2 -- buffer
			elseif pointer <= 87 then
			3 -- string
			elseif pointer <= 135 then
			4 -- number
			elseif pointer <= 193 then
			5 -- vector
			elseif pointer <= 201 then
			6 -- table
			elseif pointer <= 223 then
			7 -- userdata
			else 0 -- add more if statements if needed for future
	end

	local deserial = modules[pointer]
	if deserial then
		local originalData = deserial(value, 0)
		return originalData
	end

	deserial = require(`@self/{enumerator[pointer]}`).deserialize
	modules[pointer] = deserial
	
	local originalData = deserial(value, 0)
	return originalData
end

BufferSerializer.pair = function(id: number, value: any): nil
	local typeV = type(value)
	local maxId = if typeV == "string" then 1343
		elseif typeV == "number" then 1055
		elseif typeV == "vector" then 1055
		elseif typeV == "userdata" then 1039
		else 0

	assert(maxId ~= 0, `Invalid type {typeV} (must be string | number | vector | userdata)`)
	assert(type(id) == "number" and id % 1 == 0 and id == id, `Invalid id {id} (must be integer)`)
	assert(id >= 1 and id <= maxId, `Invalid id {id} (must be between 1 and {maxId})`)
	assert(value == value, `Invalid value {value} (must be non-nan)`)

	local mod = require(`@self/{typeV}`)
	mod.Read[id] = value
	mod.Write[value] = id
end

return BufferSerializer
