--!optimize 2
--!strict
local inflate = require("./inflate")

local CUSTOM = 202
local NIL = 203

export type Support = {
	tag: (udata: any) -> number?,
	serialize: (udata: any, tag: number) -> any?,
	deserialize: (data: any, tag: number) -> any?,
}

local supports = {
	tags = {},
	serializers = {},
	deserializers = {},
}

local function writeNil(buf: buffer, pos: number, size: number)
	if pos + 1 > size then
		buf, size = inflate(buf, pos + 1, size)
	end
	buffer.writeu8(buf, pos, NIL)
	return buf, pos + 1, size
end

local function userSerializer(value: any, buf: buffer, pos: number, size: number)
	if #supports.tags == 0 then
		return writeNil(buf, pos, size)
	end

	local tag: number? = nil
	local store: any? = nil
	for _, tagger in supports.tags do
		local temp_tag = tagger(value)
		if temp_tag then
			tag = temp_tag
			break
		end
	end

	if type(tag) ~= "number" then
		return writeNil(buf, pos, size)
	end

	for _, serializer in supports.serializers do
		local temp_store = serializer(value, tag)
		if temp_store ~= nil then
			store = temp_store
			break
		end
	end

	if store == nil then
		return writeNil(buf, pos, size)
	end

	if pos + 3 > size then
		buf, size = inflate(buf, pos + 3, size)
	end
	buffer.writeu8(buf, pos, CUSTOM)
	buffer.writeu8(buf, pos + 1, tag)

	return buf, pos + 2, size, nil, store
end

--[[
	Produces a userdata from the buffer starting at the given position.

	@param buf buffer containing the userdata
	@param pos the starting position of the userdata

	@error buffer access out of bounds

	@return the userdata and the end of the userdata position + 1
]]
local function userDeserializer(buf: buffer, pos: number)
	local id = buffer.readu8(buf, pos)

	if id == NIL then
		return newproxy(), pos + 1
	end

	if id ~= CUSTOM then
		error("... not custom")
	end

	local tag = buffer.readu8(buf, pos + 1)
	local data_id = buffer.readu8(buf, pos + 2)
	local data = nil
	-- if upfunc is deserialize then we can just (buf, pos + 2)
	-- else we need to do (ud, pos + 2)
	-- but what if external function calls this?  doesn't it kinda defeat the purpose?
	-- but debug is not the solution at ALL
	-- since it relies on known fns calling
	-- so it needs to be passed the data.. but... it cannot...
	-- just try,,,
	local upfunc, upname = debug.info(2, "fn")
	if upname == "deserialize" then
		data = upfunc(buf, pos + 2)
	else
		data = upfunc(data_id, pos + 2)
	end

	for _, deserializer in supports.deserializers do
		local temp_data = deserializer(data, tag)
		if temp_data ~= nil then
			data = temp_data
			break
		end
	end

	if data == nil then
		error("user does not support a serialized userdata")
	end

	return data, pos + 3
end

function addSupport(record: Support)
	assert(type(record) == "table", `expected table (got {type(record)})`)

	for name, value in record :: { [string]: any } do
		assert(
			name == "tag" or name == "serialize" or name == "deserialize",
			`only "tag", "serialize", or "deserialize" can be within record`
		)
		assert(
			type(value) == "function",
			`record.{name} must be a function (got {type(value)})`
		)
	end

	table.insert(supports.tags, 1, record.tag)
	table.insert(supports.serializers, 1, record.serialize)
	table.insert(supports.deserializers, 1, record.deserialize)
end

-- TODO: Question what happens supports are cleared in-transit
-- Continues as normal.
function clearSupport(keepNLatest: number?)
	if keepNLatest == nil then
		table.clear(supports.tags)
		table.clear(supports.serializers)
		table.clear(supports.deserializers)
		return
	end
	assert(
		type(keepNLatest) == "number",
		`expected number (got {type(keepNLatest)})`
	)

	for i = #supports.tags, 1, -1 do
		if i >= keepNLatest then
			return
		end
		table.remove(supports.tags, i)
		table.remove(supports.serializers, i)
		table.remove(supports.deserializers, i)
	end
end

local Userdata = {
	serialize = userSerializer,
	deserialize = userDeserializer,
	addSupport = addSupport,
	clearSupport = clearSupport,
}

return table.freeze(Userdata)
