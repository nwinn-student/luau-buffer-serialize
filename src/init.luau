--!optimize 2
--!strict

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

local calcId = link.calculateId
local linkSet = link.set
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
	Serializes the provided value into a buffer.

	- Follows the specified format in [FORMAT.md](../FORMAT.md).

	**Recommendations:**
	- Protect value from concurrent modifications, specifically tables and buffers.

	**Example:**
	```luau
	local BufferSerializer = require("./path/to/BufferSerializer")

	local serialData = BufferSerializer.serialize({ "Foo", "Foo" })
	```

	@param value the value to serialize
	
	@return a buffer representing the serialized value
]]
function BufferSerializer.serialize(value: any): buffer
	local typeValue = type(value)
	if typeValue == "function" or typeValue == "thread" then
		typeValue = "nil"
	end

	local serial: Serialize = (serialModules :: any)[typeValue]

	return trim(serial(value, nil, 0, 0))
end

--[[
	Deserializes the provided buffer, producing the value originally serialized.

	- Operates under the assumption that the buffer follows the specified format in
	 [FORMAT.md](../FORMAT.md).
	- Capable of deserializing values impossible for `serialize` to produce.

	**Recommendations:**
	- Protect value from concurrent modifications.

	**Example:**
	```luau
	local BufferSerializer = require("./path/to/BufferSerializer")
	local serialData = BufferSerializer.serialize({ "Foo", "Foo" })

	local originData = BufferSerializer.deserialize(serialData)
	```

	@param value buffer containing a serialized value

	@error buffer access out of bounds

	@return the original value
]]
function BufferSerializer.deserialize(value: buffer): any
	local pointer = buffer.readu8(value, 0)
	if pointer == 0 then
		return nil
	end

	pointer = linkType(pointer)

	local deserial: Deserialize = (deserialModules :: any)[pointer]

	return (deserial(value, 0))
end

-- narrows the type emitted by `type(any): string` would like for it to error
type TYPES = "userdata" | "number" | "string" | "vector"

--[[
	Pairs, or links, an id(entifier) to a value.

	- Ids replace the value when serializing, should the value be rawequal.
		- Only applicable within tables.
		- Initially stored [ID][VALUE], all further instances of the value are
		 stored as [ID].
	- Values replace the id when deserializing.
	- Equivalent userdata may not be rawequal
		- See [userdata.luau](./userdata.luau) for information about supporting
		 userdata.

	- Ids are stored as 1-2 bytes, depending on the number associated with the id
	 and the value's type.

	| **Type**   | **Id Range**    | **Cost** |
	|------------|-----------------|----------|
	| `string`   | 1-64            | 1 byte   |
	| `number`   | 1-32            | 1 byte   |
	| `vector`   | 1-32            | 1 byte   |
	| `userdata` | 1-16            | 1 byte   |
	|            |                 |          |
	| `string`   | 65-1343         | 2 bytes  |
	| `number`   | 33-1055         | 2 bytes  |
	| `vector`   | 33-1055         | 2 bytes  |
	| `userdata` | 16-1039         | 2 bytes  |

	**Recommendations:**
	- Calculate the word frequency of your dataset to determine which values to link to
	 what ids.
	- Ensure that linked values cannot be stored for less than or equal to the associated
	 id cost (in bytes).
	- Spare a range of ids for future additions.
	- When concurrently modifying pairs, ensure that an id is not assigned to a different
	 value.

	**Example:**
	```luau
	local BufferSerializer = require("./path/to/BufferSerializer")

	-- 5 is between 1 and 64, so it will take 1 byte to store "Foo"
	BufferSerializer.pair(5, "Foo")

	local serialData = BufferSerializer.serialize({ "Foo", "Foo" })
	```

	@param id the number associated with the value
	@param value the value reference compared against when serializing

	@error Invalid type: When the value is not a string, number, vector, or userdata
	@error Invalid id: When the id is not an integer
	@error Invalid id: When the id is not between 1 and N, where N depends on the value's type
	@error Invalid value: When the value is NaN
	@error Invalid number: When the value is 0 or 1
	@error Invalid string: When the value is ""
	@error Invalid vector: When the value is a built-in vector constant
]]
function BufferSerializer.pair(id: number, value: any): ()
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
		`Invalid id {id} (must be an integer)`
	)
	assert(
		id >= 1 and id <= maxId,
		`Invalid id {id} (must be between 1 and {maxId})`
	)
	assert(value == value, `Invalid value {value} (must be non-nan)`)
	assert(
		typeV ~= "number" or value ~= 0 and value ~= 1,
		`Invalid number {value} (cannot be a built-in [0 or 1])`
	)
	assert(
		typeV ~= "string" or value ~= "",
		`Invalid string {value} (cannot be a built-in [""])`
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
		`Invalid vector {value} (cannot be a built-in)`
	)

	linkSet(value, calcId(id, typeV))
end

return table.freeze(BufferSerializer)
