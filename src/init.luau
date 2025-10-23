--!optimize 2
--!strict
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

local BufferSerializer = {}

local serialModules = {}
local deserialModules = {}
local pairModules = require("@self/link") :: { [any]: any }

type Serialize = (
	value: any,
	buf: buffer?,
	pos: number,
	size: number
) -> (buffer, number, number)
type Deserialize = (value: buffer, pos: number) -> (any, number)
type Pair = {
	[any]: any,
	Write: { [any]: any },
}

--[[
	Returns the value as a buffer
	
	@param value the value to serialize
	
	@return a buffer representing the serialized value
]]
BufferSerializer.serialize = function(value: any): buffer
	local typeValue = type(value)
	if typeValue == "function" or typeValue == "thread" then
		typeValue = "nil"
	end

	local serial: Serialize = serialModules[typeValue]
	if not serial then
		local temp = if typeValue == "nil"
			then require("@self/nil")
			elseif typeValue == "boolean" then require("@self/boolean")
			elseif typeValue == "buffer" then require("@self/buffer")
			elseif typeValue == "string" then require("@self/string")
			elseif typeValue == "number" then require("@self/number")
			elseif typeValue == "vector" then require("@self/vector")
			elseif typeValue == "table" then require("@self/table")
			else require("@self/userdata")

		serial = temp.serialize :: Serialize
		serialModules[typeValue] = serial
	end
	return trim(serial(value, nil, 0, 0, true))
end

--[[
	Returns the original value within the buffer
	
	@param value the buffer containing the original value
	
	@return the original value
]]
BufferSerializer.deserialize = function(value: buffer): any
	local pointer = buffer.readu8(value, 0)
	if pointer == 0 then
		return nil
	end

	pointer = if pointer <= 2
		then 1 -- boolean
		elseif pointer <= 8 then 2 -- buffer
		elseif pointer <= 87 then 3 -- string
		elseif pointer <= 135 then 4 -- number
		elseif pointer <= 193 then 5 -- vector
		elseif pointer <= 201 then 6 -- table
		elseif pointer <= 223 then 7 -- userdata
		else 0 -- add more if statements if needed for future

	local deserial: Deserialize = deserialModules[pointer]
	if not deserial then
		local temp = if pointer == 0
			then require("@self/nil")
			elseif pointer == 1 then require("@self/boolean")
			elseif pointer == 2 then require("@self/buffer")
			elseif pointer == 3 then require("@self/string")
			elseif pointer == 4 then require("@self/number")
			elseif pointer == 5 then require("@self/vector")
			elseif pointer == 6 then require("@self/table")
			else require("@self/userdata")

		deserial = temp.deserialize
		deserialModules[pointer] = deserial
	end

	local originalData = deserial(value, 0)
	return originalData
end

--[[
	Connects a constant value to an identifier.
	@ Only certain types are supported.
	
	@param id the identifier
	@param value the value
]]
BufferSerializer.pair = function(id: number, value: any): ()
	local typeV = type(value)
	local maxId = if typeV == "string"
		then 1343
		elseif typeV == "number" then 1055
		elseif typeV == "vector" then 1055
		elseif typeV == "userdata" then 1039
		else 0

	assert(
		maxId ~= 0,
		`Invalid type {typeV} (must be string | number | vector | userdata)`
	)
	assert(
		type(id) == "number" and id % 1 == 0 and id == id,
		`Invalid id {id} (must be integer)`
	)
	assert(
		id >= 1 and id <= maxId,
		`Invalid id {id} (must be between 1 and {maxId})`
	)
	assert(value == value, `Invalid value {value} (must be non-nan)`)
	assert(
		typeV ~= "number" or value ~= 0 and value ~= 1,
		`Invalid value {value} (cannot be a built-in [0 or 1])`
	)
	assert(
		typeV ~= "string" or value ~= "",
		`Invalid value {value} (cannot be a built-in [""])`
	)
	assert(
		typeV ~= "vector"
			or value ~= vector.zero
				and value ~= vector.one
				and value ~= vector.create(0, 0, 1)
				and value ~= vector.create(0, 1, 0)
				and value ~= vector.create(0, 1, 1)
				and value ~= vector.create(1, 0, 0)
				and value ~= vector.create(1, 0, 1)
				and value ~= vector.create(1, 1, 0),
		`Invalid value {value} (cannot be a built-in)`
	)

	pairModules[value] = id
end

return BufferSerializer
