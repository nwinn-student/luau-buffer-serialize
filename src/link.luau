--!optimize 2
--!strict

local inflate = require("./inflate")

local link = {}

type TYPES = "userdata" | "number" | "string" | "vector"
type SERIALIZABLE_TYPES = TYPES | "boolean" | "buffer" | "nil" | "table"

local STRING_COUNT = 64
local NUMBER_COUNT = 32
local VECTOR_COUNT = 32
local USER_COUNT = 10

local STRING_START = 18
local NUMBER_START = 99
local VECTOR_START = 157
local USER_START = 203

local STRING_DUOSTART = 83
local NUMBER_DUOSTART = 132
local VECTOR_DUOSTART = 190
local USER_DUOSTART = 214

-- string: 1 to 1343
-- number: 1 to 1055
-- vector: 1 to 1055
-- userdata: 1 to 521

local values = {}

function link.get(key: any): number?
	return values[key]
end
function link.set(key: any, value: number?)
	if value == nil then
		values[key] = nil
		return
	end

	local typeKey = type(key)
	assert(typeKey == "string"
		or typeKey == "number"
		or typeKey == "vector"
		or typeKey == "userdata",
		`expected supported (got {typeKey})`
	)
	assert(
		type(value) == "number" and id % 1 == 0 and id == id,
		`Invalid id {id} (must be an integer)`
	)

	local count = if type == "string"
		then STRING_COUNT
		elseif type == "number" then NUMBER_COUNT
		elseif type == "vector" then VECTOR_COUNT
		else USER_COUNT

	if value <= 255 then
		local start = if type == "string"
			then STRING_START
			elseif type == "number" then NUMBER_START
			elseif type == "vector" then VECTOR_START
			else USER_START

		local id = value - start
		-- TODO: Verify these
		assert(
			id >= start,
			`{typeName} must be above {start} (got {id})`
		)
				assert(
			id <= count + start,
			`{typeName} must be below {count + start} (got {id})`
		)
	else
		local duostart = if type == "string"
			then STRING_DUOSTART
			elseif type == "number" then NUMBER_DUOSTART
			elseif type == "vector" then VECTOR_DUOSTART
			else USER_DUOSTART

		-- Closest estimate (at most 0.005 less than int, NEVER more
		local id = (value - duostart) / ( 256 + 1/256 ) + count

		-- TODO: Check range (ALWAYS equal or between count and count + 256n)
		-- where n is 2-4
		
	end

	values[key] = value
end
function link.clear()
	table.clear(values)
end
function link.length()
	return #values
end

--[[
	Appends the id to the buffer at the given position, returning the inputs.

	@param id the internal representation of the id associated with a value
	@param buf the buffer to append the id to
	@param pos the position in the buffer to append the id to
	@param size the size of the buffer
]]
@native
function link.serialize(id: number, buf: buffer, pos: number, size: number)
	if pos + 2 > size then
		buf, size = inflate(buf, pos + 2, size)
	end
	buffer.writeu16(buf, pos, id)
	return buf, pos + (id > 255 and 2 or 1), size, id :: any
end

--[[
	Returns the internal representation of the id based on the provided type.
	That is, the value to store when serializing the value in tables.

	@param id the id to pair to a value
	@param type the type of the paired value
]]
@native
function link.calculateId(id: number, type: TYPES): number
	local count = if type == "string"
		then STRING_COUNT
		elseif type == "number" then NUMBER_COUNT
		elseif type == "vector" then VECTOR_COUNT
		else USER_COUNT

	local start = if type == "string"
		then STRING_START
		elseif type == "number" then NUMBER_START
		elseif type == "vector" then VECTOR_START
		else USER_START

	local duostart = if type == "string"
		then STRING_DUOSTART
		elseif type == "number" then NUMBER_DUOSTART
		elseif type == "vector" then VECTOR_DUOSTART
		else USER_DUOSTART

	local calcId

	-- stored in 1,2 byte(s) respectively
	if id <= count then
		calcId = id + start
	else
		local constVal = id - count
		calcId = constVal * 256 + (duostart + constVal // 256)
	end

	return calcId
end

--[[
	Returns the type of reference id

	@param refId the byte containing the type and location of the id paired to a value
]]
@native
function link.type(refId: number): SERIALIZABLE_TYPES
	return if refId <= 2
		then "boolean"
		elseif refId <= 8 then "buffer"
		elseif refId <= 87 then "string"
		elseif refId <= 135 then "number"
		elseif refId <= 193 then "vector"
		elseif refId <= 201 then "table"
		elseif refId <= 215 then "userdata"
		else "nil" -- add more if statements if needed for future
end

--[[
	Returns whether the byte is linked

	@param byte the byte read
	@param type value type
]]
@native
function link.islink(byte: number, type: SERIALIZABLE_TYPES): boolean
	return type == "string" and byte > STRING_START
		or type == "number" and byte > NUMBER_START
		or type == "vector" and byte > VECTOR_START
		or type == "userdata" and byte > USER_START
end

--[[
	Returns whether the value associated with the link is 2 bytes

	@param byte the byte read
	@param type the value type
]]
@native
function link.isduo(byte: number, type: SERIALIZABLE_TYPES): boolean
	return type == "string" and byte >= STRING_DUOSTART
		or type == "number" and byte >= NUMBER_DUOSTART
		or type == "vector" and byte >= VECTOR_DUOSTART
		or type == "userdata" and byte >= USER_DUOSTART
end

return table.freeze(link)
