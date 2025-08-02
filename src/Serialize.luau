--!optimize 2
local enumerator = require("./internal/pointer/Enumerator")

do
	require("./internal/table") -- ensures the rest are loaded
end

local support = enumerator.support
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

	local Data = {Position=0, Data=nil, Size=nil}

	local serial = modules[typeValue]
	if not serial then
		serial = require(`./internal/{typeValue}`).serialize
		modules[typeValue] = serial
	end
	serial(value, Data)
	trim(Data)

	return Data.Data
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

	local PositionData = {Position = 0}

	local deserial = modules[pointer]
	if deserial then
		return deserial(value, PositionData)
	end

	deserial = require(`./internal/{enumerator[pointer]}`).deserialize
	modules[pointer] = deserial
	return deserial(value, PositionData)
end

return Serialize