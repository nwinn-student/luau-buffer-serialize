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
function BufferSerializer.serialize(value: any): buffer
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
	return trim(serial(value, nil, 0, 0))
end

--[[
	Returns the original value within the buffer

	@param value the buffer containing the original value
	
	@return the original value
]]
function BufferSerializer.deserialize(value: buffer): any
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
	Pairs, or links, an id(entifier) to a value.

	- Serialization: The value is converted to the id.
	 	- "Foo", whose id is 5, is `string: 0x0000020e7de21260`, thus all "Foo"s **must** also
	 	 reference `string: 0x0000020e7de21260` to be linked with 5.
	 	- Do not expect equivalent (`==`) userdata objects to have the same reference as other userdata objects.
	 		- <details><summary>Click me to see how to check/solve</summary>

				To check: `assert( ({ [yourUserdata] = true })[otherUserdata] )`

				There are multiple solutions:
				1. Cache the userdata so it can be referenced readily, from anywhere, instead of
				 recreating equivalent userdata.  **Not always applicable**
				2. Use lightuserdata whenever possible.  **Rarely applicable**
				3. Create custom userdata writer/reader functions.
				 See [userdata](./userdata.luau) for more information.
	 		 </details>

	- Deserialization: The id is converted to the value.
		- The value **must** be linked to the id at this point.

	Identifiers are used to communicate importance:
	<!--
	 TODO: cost unclear, add clarity.
	 TODO: Potentially remove the importance notice, and just explain the below table
	 TODO: Possibly move the comments about constants into here from README.md
	-->
	<sub>Higher importance means lower cost when serializing, thus a smaller output size</sub>

	1. One byte: Highest importance, few slots available (10s)
	2. Two bytes: High importance, limited slots (100s or 1000s)
	3. N bytes: Low importance, no identifier for the value.

	| **Type**   | **Ids**    | **Cost** |
	|------------|------------|----------|
	| `string`   | 1-64       | 1 byte   |
	| `number`   | 1-32       | 1 byte   |
	| `vector`   | 1-32       | 1 byte   |
	| `userdata` | 1-16       | 1 byte   |
	|            |            |          |
	| `string`   | 65-1343    | 2 bytes  |
	| `number`   | 33-1055    | 2 bytes  |
	| `vector`   | 33-1055    | 2 bytes  |
	| `userdata` | 16-1039    | 2 bytes  |

	<sub>See [README.md](../README.md#constant-amount-supported) for more information</sub>

	<!-- TODO: Remove the comment once RISKS.md is complete.
	<sub>See [RISKS.md](../RISKS.md) to understand the risks when using `BufferSerializer.pair`.</sub>
	-->

	**Example**
	```luau
	 -- 5 is between 1 and 64, so it will take 1 byte to store "Foo" from now on
	BufferSerializer.pair(5, "Foo")
	-- 75 is between 65 and 1343, so it will take 2 bytes to store "Bar" from now on
	BufferSerializer.pair(75, "Bar")
	```

	@param id the identifier
	@param value the value

	@error Invalid type: When the value is not a string, number, vector, or userdata
	@error Invalid id: When the id is not an integer
	@error Invalid id: When the id is not between 1 and N, where N depends on the value's type
	@error Invalid value: When the value is NaN
	@error Invalid value: When the value is a built-in constant, i.e. "", 0, 1, etc
]]
function BufferSerializer.pair(id: number, value: any): ()
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

	local mod: Pair = pairModules[typeV]
	if not mod then
		mod = (
			if typeV == "string"
				then require("@self/string")
				elseif typeV == "number" then require("@self/number")
				elseif typeV == "vector" then require("@self/vector")
				else require("@self/userdata")
		) :: Pair
		pairModules[typeV] = mod
	end

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

return BufferSerializer
