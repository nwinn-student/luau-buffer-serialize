--!optimize 2
local enumerator = require("./internal/pointer/Enumerator")

local Serialize = {}
local modules = {}

--[[
	Returns the value as a buffer
]]--
Serialize.serialize = function(value: any)
	-- we must pass position as 0, always
	local pointer = enumerator.Support[type(value)]
		or enumerator.Support["nil"]
	
	local Data = {Position=0, Data=nil, Size=nil}
	
	local mod = modules[pointer]
	if not mod then
		print(enumerator[pointer])
		mod = require(`./internal/{enumerator[pointer]}`)
		modules[pointer] = mod
	end
	mod.serialize(value, Data)
	enumerator.Methods.trim(Data)
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
	
	local mod = modules[pointer]
	if mod then
		return mod.deserialize(value, PositionData)
	end
	modules[pointer] = require(`./internal/{enumerator[pointer]}`)
	return modules[pointer].deserialize(value, PositionData)
end

return Serialize