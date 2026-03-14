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
local userdata = require("@self/userdata")
local linkType = link.type

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

type Serialize = (
	value: any,
	buf: buffer?,
	pos: number,
	size: number
) -> (buffer, number, number)
type Deserialize = (value: buffer, pos: number) -> (any, number)

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

	local buf, pos, size = serial(value, nil, 0, 0)

	return trim(buf, pos, size)
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

	@error Failed to parse buffer
	@error Failed to parse string
	@error Failed to parse number
	@error Failed to parse built-in vector constant
	@error Failed to parse vector
	@error Failed to parse userdata
	@error Failed to parse custom userdata
	@error Failed to parse table
	@error Failed to parse existing value
	@error Failed to parse nil in a dictionary
	@error Failed to parse future
	@error Failed to parse extension
	@error buffer access out of bounds

	@return the original value
]]
function BufferSerializer.deserialize(value: buffer, pos: number?): any
	assert(
		pos == nil or type(pos) == "number",
		`expected pos to be number (got {type(pos)})`
	)

	local pointer = buffer.readu8(value, pos or 0)
	if pointer == 0 then
		return nil
	end

	pointer = linkType(pointer)

	local deserial: Deserialize = (deserialModules :: any)[pointer]

	return (deserial(value, pos or 0))
end

export type UserdataSupport = userdata.Support

--[[
	Adds support for a userdata or group of userdata to be
	 (de)serialized.

	@param record the container holding the (de)serialize functions

	@error expected table
	@error only "serialize" or "deserialize" can be within record
	@error record.(de)serialize must be a function
]]
function BufferSerializer.supportUserdata(record: UserdataSupport)
	userdata.addSupport(record)
end

--[[
	Returns whether the userdata is capable of being serialized and deserialized.

	- Meaning the userdata does not deserialize into the unsupported userdata constant

	@param ud the userdata to check

	@error Failed to parse userdata
	@error Failed to parse custom userdata
	@error buffer access out of bounds
]]
function BufferSerializer.isSupported(ud: any): boolean
	if ud == userdata.unsupported then
		return false
	end
	return userdata.deserialize(userdata.serialize(ud, nil :: any, 0, 0), 0)
		~= userdata.unsupported
end

return table.freeze(BufferSerializer)
