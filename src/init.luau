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
local pairModules = {}

type Serialize = (value: any, buf: buffer?, pos: number, size: number)
	-> (buffer, number, number)
type Deserialize = (value: buffer, pos: number) -> (any, number)
type Pair = {
	[any]: any, 
	Read: {[any]: any}, 
	Write: {[any]: any}
}

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

	local serial: Serialize = serialModules[typeValue]
	if not serial then
		local temp = if typeValue == "nil" then
				require("@self/nil")
			elseif typeValue == "boolean" then
				require("@self/boolean")
			elseif typeValue == "buffer" then
				require("@self/buffer")
			elseif typeValue == "string" then
				require("@self/string")
			elseif typeValue == "number" then
				require("@self/number")
			elseif typeValue == "vector" then
				require("@self/vector")
			elseif typeValue == "table" then
				require("@self/table")
			else                       
				require("@self/userdata")
		
		serial = temp.serialize :: Serialize
		serialModules[typeValue] = serial
	end
	return trim(serial(value, nil, 0, 0))
end

--[[
	Returns the original value within the buffer
	
	@param value the buffer containing the original value
	
	@return the original value
]]--
BufferSerializer.deserialize = function(value: buffer): any
	local pointer = buffer.readu8(value, 0)
	if pointer == 0 then return nil end

	pointer = if pointer <= 2 then
			1 -- boolean
		elseif pointer <= 7 then
			2 -- buffer
		elseif pointer <= 96 then
			3 -- string
		elseif pointer <= 141 then
			4 -- number
		elseif pointer <= 193 then
			5 -- vector
		elseif pointer <= 201 then
			6 -- table
		elseif pointer <= 223 then
			7 -- userdata
		else 
			0 -- add more if statements if needed for future

	local deserial: Deserialize = deserialModules[pointer]
	if not deserial then
		local temp = if pointer == 0 then
				require("@self/nil")
			elseif pointer == 1 then
				require("@self/boolean")
			elseif pointer == 2 then
				require("@self/buffer")
			elseif pointer == 3 then
				require("@self/string")
			elseif pointer == 4 then
				require("@self/number")
			elseif pointer == 5 then
				require("@self/vector")
			elseif pointer == 6 then
				require("@self/table")
			else
				require("@self/userdata")
		
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
]]--
BufferSerializer.pair = function(id: number, value: any): ()
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
	
	local mod: Pair = pairModules[typeV]
	if not mod then
		-- ...
		mod = ((if typeV == "string" then
				require("@self/string")
			elseif typeV == "number" then
				require("@self/number")
			elseif typeV == "vector" then
				require("@self/vector")
			else
				require("@self/userdata")) :: Pair)
		pairModules[typeV] = mod
	end
	mod.Read[id] = value
	mod.Write[value] = id
end

return BufferSerializer
