--!optimize 2
--!strict
local inflate = require("./inflate")

local CUSTOM = 202
local UNSUPPORTED = 203

type Support = {
	serialize: (
		udata: any,
		buf: buffer,
		pos: number,
		size: number
	) -> (buffer, number, number),
	deserialize: (buf: buffer, pos: number) -> (any?, number),
}

local UNSUPPORTED_USERDATA = newproxy()

local supports = {
	serializers = {},
	deserializers = {},
}

local function writeUnsupported(buf: buffer, pos: number, size: number)
	buf, size = inflate(buf, pos + 1, size)
	buffer.writeu8(buf, pos, UNSUPPORTED)
	return buf, pos + 1, size
end

local function userSerializer(value: any, buf: buffer, pos: number, size: number)
	if #supports.serializers == 0 or value == UNSUPPORTED_USERDATA then
		return writeUnsupported(buf, pos, size)
	end

	local end_buf: buffer, end_pos: number, end_size: number
	local isSupported: boolean = false

	buf, size = inflate(buf, pos + 2, size)
	buffer.writeu8(buf, pos, CUSTOM)

	-- this is faster than functions that call functions (since we would need to wrap each)
	for _, serializer in supports.serializers do
		local temp_buf, temp_pos, temp_size =
			serializer(value, buf, pos + 1, size)
		if temp_pos ~= pos + 1 then
			isSupported = true
			end_buf, end_pos, end_size = temp_buf, temp_pos, temp_size
			break
		end
	end

	-- we assume no modifications to the buffer!!
	if not isSupported then
		return writeUnsupported(buf, pos, size)
	end

	return end_buf, end_pos, end_size
end

--[[
	Produces a userdata from the buffer starting at the given position.

	@param buf buffer containing the userdata
	@param pos the starting position of the userdata

	@error Failed to parse userdata
	@error Failed to parse custom userdata
	@error buffer access out of bounds

	@return the userdata and the end of the userdata position + 1
]]
local function userDeserializer(buf: buffer, pos: number)
	-- Possible optim: We actually get the id multiple times for table, can we pass the id?
	local id = buffer.readu8(buf, pos)

	if id == UNSUPPORTED then
		return UNSUPPORTED_USERDATA, pos + 1
	end

	if id ~= CUSTOM then
		error(`Failed to parse userdata using byte: {id} at position {pos}`)
	end

	local data = nil

	for _, deserializer in supports.deserializers do
		local temp_data, temp_pos
		temp_data, temp_pos = deserializer(buf, pos + 1)
		if temp_data ~= nil then
			data = temp_data
			pos = temp_pos
			break
		end
	end

	-- no returning values that cause tables to error
	if data == nil or data ~= data then
		local nextId = buffer.readu8(buf, pos + 1)
		error(
			`Failed to parse custom userdata using byte: {nextId} at position {pos + 1}`
		)
	end

	return data, pos
end

--[[
	Adds support for a userdata or group of userdata to be
	 (de)serialized.

	- The provided functions will be called on a last to first supported basis.
	- Duplicate support functions will be shifted to the front.

	**Recommendations:**
	- Focus on reducing the number of supported functions created.
	- Group userdata supported by the same environment/runtime together.
	- Consider that later supported functions may attempt to handle the
	 supported userdata, which may be undesirable since they are called **first**.
	  - If undesirable, privatize `BufferSerializer` and provide a public wrapper that
	   replaces `bs.supportUserdata` with:
	  ```luau
	  local function supportUserdata(record): ()
		bs.supportUserdata(record)
		bs.supportUserdata(main_record) -- record that must run first
	  end
	  ```
	- Provide and read documentation surrounding the supported userdata.
	  - Conflicting bytecode or opcodes will either corrupt data or cause errors.

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
function addSupport(record: Support)
	assert(
		type(record) == "table",
		`Invalid type: expected table (got {type(record)})`
	)
	assert(record.serialize, `Incomplete record: missing property serialize`)
	assert(record.deserialize, `Incomplete record: missing property deserialize`)

	for name, value in record :: { [string]: any } do
		assert(
			name == "serialize" or name == "deserialize",
			`Invalid property: {name} is not "serialize" or "deserialize"`
		)
		assert(
			type(value) == "function",
			`Invalid property type: expected function for {name} (got {type(value)})`
		)
	end

	local old_serial_pos = table.find(supports.serializers, record.serialize)
	local old_deserial_pos =
		table.find(supports.deserializers, record.deserialize)

	table.insert(supports.serializers, 1, record.serialize)
	table.insert(supports.deserializers, 1, record.deserialize)

	if old_serial_pos then
		table.remove(supports.serializers, old_serial_pos + 1)
	end
	if old_deserial_pos then
		table.remove(supports.deserializers, old_deserial_pos + 1)
	end
end

--[[
	Removes (de)serialization support for some userdata

	@param keepNLatest how many supported functions to keep
]]
function clearSupport(keepNLatest: number?)
	if keepNLatest == nil then
		table.clear(supports.serializers)
		table.clear(supports.deserializers)
		return
	end
	assert(
		type(keepNLatest) == "number",
		`expected number (got {type(keepNLatest)})`
	)

	local maxLength = math.max(#supports.serializers, #supports.deserializers)

	for i = maxLength, 1, -1 do
		if i >= keepNLatest then
			break
		end
		table.remove(supports.serializers, i)
		table.remove(supports.deserializers, i)
	end
end

local Userdata = {
	serialize = userSerializer,
	deserialize = userDeserializer,
	addSupport = addSupport,
	clearSupport = clearSupport,

	unsupported = UNSUPPORTED_USERDATA,
}

return table.freeze(Userdata)
