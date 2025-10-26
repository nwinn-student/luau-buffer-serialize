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
local link = require("@self/link")

local serialModules = table.freeze({
	["nil"] = require("@self/nil").serialize,
	boolean = require("@self/boolean").serialize,
	buffer = require("@self/buffer").serialize,
	string = require("@self/string").serialize,
	number = require("@self/number").serialize,
	vector = require("@self/vector").serialize,
	table = require("@self/table").serialize,
	userdata = require("@self/userdata").serialize,
})
local deserialModules = table.freeze({
	["nil"] = require("@self/nil").deserialize,
	boolean = require("@self/boolean").deserialize,
	buffer = require("@self/buffer").deserialize,
	string = require("@self/string").deserialize,
	number = require("@self/number").deserialize,
	vector = require("@self/vector").deserialize,
	table = require("@self/table").deserialize,
	userdata = require("@self/userdata").deserialize,
})
local pairModules = link.values :: { [any]: any }

local calcId = link.calculateId
local linkType = link.type

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

	local serial: Serialize = (serialModules :: any)[typeValue]

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

	pointer = linkType(pointer)

	local deserial: Deserialize = (deserialModules :: any)[pointer]

	local originalData = deserial(value, 0)
	return originalData
end

-- narrows the type emitted by `type(any): string` would like for it to error
type TYPES = "userdata" | "number" | "string" | "vector"

--[[
	Connects a constant value to an identifier.
	@ Only certain types are supported.
	
	@param id the identifier
	@param value the value
]]
BufferSerializer.pair = function(id: number, value: any): ()
	local typeV = type(value) :: TYPES
	local maxId = if typeV == "string"
		then 1343
		elseif typeV == "number" then 1055
		elseif typeV == "vector" then 1055
		elseif typeV == "userdata" then 521
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

	pairModules[value] = calcId(id, typeV)
end

return table.freeze(BufferSerializer)
