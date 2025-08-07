--!optimize 2
local enumerator = require("./internal/pointer/Enumerator")

do
	require("./internal/table") -- ensures the rest are loaded
end

local trim = enumerator.Methods.trim

local Serialize = {}
local modules = {}

--[[
	Returns the value as a buffer
]]--
Serialize.serialize = function(value: any)
	local typeValue = type(value)
	if typeValue == "function" or typeValue == "thread" then
		typeValue = "nil"
	end

	local serial = modules[typeValue]
	if not serial then
		serial = require(`./internal/{typeValue}`).serialize
		modules[typeValue] = serial
	end
	return trim(serial(value, nil, 0, 0))
end

Serialize.deserialize = function(value: buffer)
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
		return deserial(value, 0)
	end
	
	deserial = require(`./internal/{enumerator[pointer]}`).deserialize
	modules[pointer] = deserial
	return deserial(value, 0)
end

Serialize.pair = function(id: number, value: any)
	local typeV = type(value)
	local maxId = if typeV == "string" then 1343
		elseif typeV == "number" then 1055
		elseif typeV == "vector" then 1055
		elseif typeV == "userdata" then 1039
		else 0

	assert(type(id) == "number" and id % 1 == 0, `Invalid id {id} (must be integer)`)
	assert(id >= 1 and id <= maxId, `Invalid id {id} (must be between 1 and {maxId})`)
	assert(value == value, `Invalid value {value} (must be non-nan)`)

	local mod = require(`./internal/{typeV}`)
	mod.Read[id] = value
	mod.Write[value] = id
end

return Serialize