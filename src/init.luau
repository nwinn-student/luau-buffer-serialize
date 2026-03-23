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

-- TODO: Add documentation
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
	buf: buffer,
	pos: number,
	size: number
) -> (buffer, number, number)
type Deserialize = (buf: buffer, pos: number) -> (any, number)

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

	local buf, pos, size = serial(value, nil :: any, 0, 0)

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
function BufferSerializer.deserialize(value: buffer): any
	local pointer = buffer.readu8(value, 0)
	if pointer == 0 then
		return nil
	end

	pointer = linkType(pointer)

	local deserial: Deserialize = (deserialModules :: any)[pointer]

	return (deserial(value, 0))
end

--[[
	A dictionary for `BufferSerializer.supportUserdata`, with the following available values:
	- `serialize` - A function for serializing userdata
	- `deserialize` - A function for deserializing userdata
]]
export type UserdataSupport = {
	--[[
		Inserts the serialized form of the value into the provided buffer
		 starting at the given position.

		@param value - the userdata to serialize
		@param buf - the current buffer to store the serialized form in
		@param pos - the current position
		@param size - the current size of the buffer

		@return the buffer containing the serialized form
		@return the starting position for the next item, (1 + position last modified)
		@return the size of the buffer
	]]
	serialize: Serialize,
	--[[
		Produces a userdata from the buffer starting at the given position.

		@param buf buffer containing the userdata
		@param pos the starting position of the userdata

		@error buffer access out of bounds

		@return the userdata and the end userdata position + 1
	]]
	deserialize: Deserialize,
}

--[[
	Adds support for a userdata or group of userdata to be
	 (de)serialized.

	- The provided functions will be called on a last to first supported basis.
	- Duplicate support functions will be shifted to the front.

	**Recommendations:**
	- Group userdata supported by the same environment/runtime together.
	- Consider that later supported functions may attempt to handle the
	 supported userdata, which may be undesirable since they are called **first**.
	  - If undesirable, privatize `BufferSerializer` and provide a public wrapper that
	   replaces `bs.supportUserdata` with:
	  ```luau
	  local function supportUserdata(record: bs.UserdataSupport): ()
		bs.supportUserdata(record)
		-- main_record is defined earlier and **must** run first
		bs.supportUserdata(main_record)
	  end
	  ```
	- Provide and read documentation surrounding the supported userdata.
	  - Conflicting bytecode or opcodes will either corrupt data or cause errors.
	  - Removing or modifying support can also corrupt data or cause errors.

	**Example**
	```luau
	local BufferSerializer = require("@BufferSerializer")

	local sample_userdata = newproxy()
	local sample_id = 0

	BufferSerializer.supportUserdata({
		serialize = function(value: any, buf: buffer, pos: number, size: number)
			if value ~= sample_userdata then
				return buf, pos, size
			end
			buffer.writeu8(buf, pos, sample_id)
			return buf, pos + 1, size
		end,
		deserialize = function(buf: buffer, pos: number)
			local id = buffer.readu8(buf, pos)
			if id == sample_id then
				return sample_userdata, pos + 1
			end
			return nil, pos
		end,
	})

	local serialData = BufferSerializer.serialize(sample_userdata)
	```

	@param record the container holding the (de)serialize functions

	@error Invalid type: When record is not a table
	@error Incomplete record: When record is missing (de)serialize
	@error Invalid property: When the property isn't (de)serialize
	@error Invalid property type: When (de)serialize isn't a function
]]
function BufferSerializer.supportUserdata(record: UserdataSupport)
	userdata.addSupport(record)
end

--[[
	Returns whether the userdata is capable of being serialized and deserialized.

	- Meaning the userdata does not deserialize into the unsupported userdata constant

	**Recommendations:**
	- Ensure the userdata deserializes into the desired form.

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
