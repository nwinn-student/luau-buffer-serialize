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

local modules = table.freeze({
	["nil"] = require("@self/nil"),
	boolean = require("@self/boolean"),
	buffer = require("@self/buffer"),
	string = require("@self/string"),
	number = require("@self/number"),
	vector = require("@self/vector"),
	table = require("@self/table"),
	userdata = require("@self/userdata"),

	[0] = require("@self/nil").deserialize,
	require("@self/boolean").deserialize,
	require("@self/buffer").deserialize,
	require("@self/string").deserialize,
	require("@self/number").deserialize,
	require("@self/vector").deserialize,
	require("@self/table").deserialize,
	require("@self/userdata").deserialize
})

type Serialize = (
	value: any,
	buf: buffer?,
	pos: number,
	size: number
) -> (buffer, number, number)
type Deserialize = (value: buffer, pos: number) -> (any, number)
type Pair = {
	[any]: any,
	Read: { [any]: any },
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

	local serial: Serialize = (modules[typeValue :: any] :: any).serialize

	return trim(serial(value, nil, 0, 0))
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

	local deserial: Deserialize = modules[pointer]

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

	local mod: Pair = modules[typeV :: any] :: any

	-- Same value, different id
	if mod.Write[value] ~= nil then
		mod.Read[mod.Write[value]] = nil
	end
	-- Same id, different value
	if mod.Read[id] ~= nil then
		mod.Write[mod.Read[id]] = nil
	end
	mod.Read[id] = value
	mod.Write[value] = id
end

return table.freeze(BufferSerializer)
