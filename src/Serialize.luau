--!optimize 2
local enumerator = require("./internal/pointer/Enumerator")

local support = enumerator.support
local trim = enumerator.Methods.trim

local Serialize = {}
local modules = {}

local dataCache = {}
local lenCache = 0

--[[
	Returns the value as a buffer
]]--
Serialize.serialize = function(value: any)
	local typeValue = type(value)
	if typeValue == "function" or typeValue == "thread" then
		typeValue = "nil"
	end
	
	local Data
	if lenCache > 0 then
		Data = dataCache[lenCache]
		Data.Position = 0
		lenCache -= 1
	else
		Data = {Position=0, Data=nil, Size=nil}
	end
	
	local serial = modules[typeValue]
	if not serial then
		serial = require(`./internal/{typeValue}`).serialize
		modules[typeValue] = serial
	end
	serial(value, Data)
	trim(Data)
	
	local retData = Data.Data
	if lenCache < 10 then
		dataCache[lenCache + 1] = Data
		table.clear(Data)
		lenCache += 1
	end
	return retData
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
	
	local mod = modules[pointer]
	if mod then
		return mod.deserialize(value, PositionData)
	end
	modules[pointer] = require(`./internal/{enumerator[pointer]}`)
	return modules[pointer].deserialize(value, PositionData)
end

return Serialize