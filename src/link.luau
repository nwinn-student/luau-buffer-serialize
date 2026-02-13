--!optimize 2
--!strict

local inflate = require("./inflate")

local link = {}

type TYPES = "userdata" | "number" | "string" | "vector"
type SERIALIZABLE_TYPES = TYPES | "boolean" | "buffer" | "nil" | "table"

local STRING_START = 27
local NUMBER_START = 105
local VECTOR_START = 157
local USER_START = 203

local STRING_DUOSTART = 92
local NUMBER_DUOSTART = 138
local VECTOR_DUOSTART = 190
local USER_DUOSTART = 214

-- string: 1 to 1343
-- number: 1 to 1055
-- vector: 1 to 1055
-- userdata: 1 to 521

--[[
	Returns the type of reference id

	@param refId the byte containing the type and location of the id paired to a value
]]
@native
function link.type(refId: number): SERIALIZABLE_TYPES
	return if refId == 0
		then "nil"
		elseif refId <= 2 then "boolean"
		elseif refId <= 7 then "buffer"
		elseif refId <= 96 then "string"
		elseif refId <= 141 then "number"
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
