--!optimize 2
local enumerator = require("./pointer/Enumerator")

local Nil = require("./nil")
local Boolean = require("./boolean")
local Buffer = require("./buffer")
local String = require("./string")
local Number = require("./number")
local Vector = require("./vector")
local Userdata = require("./userdata")

local grow = enumerator.Methods.grow

enumerator = nil

local EMPTY = 194
local TABLE = 195
local EQ_EXISTING = 196
local ARRAY = 197
local DICT = 198
local ARRAY_END = 199
local TABLE_END = 200

@native
local function tabSerialize(value: {[any]: any}, buf: buffer, pos: number, parExisting: {Data: {[any]:any}, Index: number}?)

	if next(value) == nil then
		buf = grow(buf, pos, 1)
		buffer.writeu8(buf, pos, EMPTY)
		return buf, pos + 1
	end

	local lastIndex = 0
	local existingIndex = parExisting and parExisting.Index or 1
	local existing = parExisting and parExisting.Data or {  -- MASSIVE TABLE
		[value] = 0
	}
	if not parExisting then
		parExisting = {Data = existing, Index = existingIndex}
	end

	local one_byte_existing = {} -- for speed
	local two_byte_existing = {} -- for speed

	local isDict = #value == 0
	buf = grow(buf, pos, 1) -- 1 to say table
	buffer.writeu8(buf, pos, if isDict then DICT else TABLE)

	local tempPos = pos + 1
	local endArray = false

	for i,v in value do
		lastIndex += 1
		local isInArray = lastIndex == i

		if isInArray then
			-- fast paths
			local cached = existing[v]
			if cached then
				buf = grow(buf, tempPos, 3)
				buffer.writeu8(buf, tempPos, EQ_EXISTING)
				buffer.writeu16(buf, tempPos + 1, cached)
				tempPos += 3
				continue
			end
			-- check 1 and 2 byte caches
			cached = two_byte_existing[v]
			if cached then
				buf = grow(buf, tempPos, 2)
				buffer.writeu16(buf, tempPos, cached)
				tempPos += 2
				continue
			end
			cached = one_byte_existing[v]
			if cached then
				buf = grow(buf, tempPos, 1)
				buffer.writeu8(buf, tempPos, cached)
				tempPos += 1
				continue
			end
			local oldPos = tempPos
			
			local typeV = type(v)
			if typeV == "nil" or typeV == "function" or typeV == "thread" then
				buf, tempPos = Nil.serialize(v, buf, tempPos)
			elseif typeV == "boolean" then
				buf, tempPos = Boolean.serialize(v, buf, tempPos)
			elseif typeV == "buffer" then
				buf, tempPos = Buffer.serialize(v, buf, tempPos)
			elseif typeV == "string" then
				buf, tempPos = String.serialize(v, buf, tempPos)
			elseif typeV == "number" then
				buf, tempPos = Number.serialize(v, buf, tempPos)
			elseif typeV == "vector" then
				buf, tempPos = Vector.serialize(v, buf, tempPos)
			elseif typeV == "userdata" then
				buf, tempPos = Userdata.serialize(v, buf, tempPos)
			elseif typeV == "table" then
				parExisting.Index = existingIndex
				buf, tempPos = tabSerialize(v, buf, tempPos, parExisting)
				existingIndex = parExisting.Index
			end

			if tempPos - oldPos == 1 then
				one_byte_existing[v] = buffer.readu8(buf, tempPos)
			elseif tempPos - oldPos == 2 then
				two_byte_existing[v] = buffer.readu16(buf, tempPos)
			elseif existingIndex ~= 65_535 and v == v then
				-- cache for rest (only 65_536 values we can cache!!)
				-- v == v checks for nans :>
				existing[v] = existingIndex
				existingIndex += 1
			end
			continue
		end
		if not endArray and not isDict then
			endArray = true
			buf = grow(buf, tempPos, 1)
			buffer.writeu8(buf, tempPos, ARRAY_END)
			tempPos += 1
		end

		local typeI = type(i)
		local typeV = type(v)

		if typeI == "nil" or typeI == "function" or typeI == "thread"
			or typeV == "nil" or typeV == "function" or typeV == "thread"
		then
			continue
		end

		local keyCached = existing[i]
		if keyCached then
			buf = grow(buf, tempPos, 3)
			buffer.writeu8(buf, tempPos, EQ_EXISTING)
			buffer.writeu16(buf, tempPos + 1, keyCached)
			tempPos += 3
		end
		-- check 1 and 2 byte caches
		local twoKeyCached = not keyCached and two_byte_existing[i]
		if twoKeyCached then
			buf = grow(buf, tempPos, 2)
			buffer.writeu16(buf, tempPos, twoKeyCached)
			tempPos += 2
		end
		local threeKeyCached = not keyCached and not twoKeyCached and one_byte_existing[i]
		if threeKeyCached then
			buf = grow(buf, tempPos, 1)
			buffer.writeu8(buf, tempPos, threeKeyCached)
			tempPos += 1
		end
		
		local oldPos = tempPos
		
		-- store i
		if not keyCached and not twoKeyCached and not threeKeyCached then
			if typeI == "boolean" then
				buf, tempPos = Boolean.serialize(i, buf, tempPos)
			elseif typeI == "buffer" then
				buf, tempPos = Buffer.serialize(i, buf, tempPos)
			elseif typeI == "string" then
				buf, tempPos = String.serialize(i, buf, tempPos)
			elseif typeI == "number" then
				buf, tempPos = Number.serialize(i, buf, tempPos)
			elseif typeI == "vector" then
				buf, tempPos = Vector.serialize(i, buf, tempPos)
			elseif typeI == "userdata" then
				buf, tempPos = Userdata.serialize(i, buf, tempPos)
			elseif typeI == "table" then
				parExisting.Index = existingIndex
				buf, tempPos = tabSerialize(i, buf, tempPos, parExisting)
				existingIndex = parExisting.Index
			end

			if tempPos - oldPos == 1 then
				one_byte_existing[i] = buffer.readu8(buf, tempPos)
			elseif tempPos - oldPos == 2 then
				two_byte_existing[i] = buffer.readu16(buf, tempPos)
			elseif existingIndex ~= 65_535 then
				-- cache for rest (only 65_536 values we can cache)
				existing[i] = existingIndex
				existingIndex += 1
			end
		end

		local valueCached = existing[v]
		if valueCached then
			buf = grow(buf, tempPos, 3)
			buffer.writeu8(buf, tempPos, EQ_EXISTING)
			buffer.writeu16(buf, tempPos + 1, valueCached)
			tempPos += 3
			continue
		end
		-- check 1 and 2 byte caches
		valueCached = two_byte_existing[v]
		if valueCached then
			buf = grow(buf, tempPos, 2)
			buffer.writeu16(buf, tempPos, valueCached)
			tempPos += 2
			continue
		end
		valueCached = one_byte_existing[v]
		if valueCached then
			buf = grow(buf, tempPos, 1)
			buffer.writeu8(buf, tempPos, valueCached)
			tempPos += 1
			continue
		end
		
		local oldPos = tempPos
		
		-- store v
		if typeV == "boolean" then
			buf, tempPos = Boolean.serialize(v, buf, tempPos)
		elseif typeV == "buffer" then
			buf, tempPos = Buffer.serialize(v, buf, tempPos)
		elseif typeV == "string" then
			buf, tempPos = String.serialize(v, buf, tempPos)
		elseif typeV == "number" then
			buf, tempPos = Number.serialize(v, buf, tempPos)
		elseif typeV == "vector" then
			buf, tempPos = Vector.serialize(v, buf, tempPos)
		elseif typeV == "userdata" then
			buf, tempPos = Userdata.serialize(v, buf, tempPos)
		elseif typeV == "table" then
			parExisting.Index = existingIndex
			buf, tempPos = tabSerialize(v, buf, tempPos, parExisting)
			existingIndex = parExisting.Index
		end

		if tempPos - oldPos == 1 then
			one_byte_existing[v] = buffer.readu8(buf, tempPos)
		elseif tempPos - oldPos == 2 then
			two_byte_existing[v] = buffer.readu16(buf, tempPos)
		elseif existingIndex ~= 65_535 and v == v then
			-- cache for rest (only 65_536 values we can cache)
			-- v == v checks for nans :>
			existing[v] = existingIndex
			existingIndex += 1
		end
	end
	
	if parExisting then
		parExisting.Index = existingIndex
	end
	
	if not isDict and not endArray then
		buffer.writeu8(buf, pos, ARRAY)
	end
	buf = grow(buf, tempPos, 1)
	buffer.writeu8(buf, tempPos, TABLE_END)
	return buf, tempPos + 1
end

@native
local function tabDeserialize(buf: buffer, pos: number, parExisting: {Data: {[any]:any}, Index: number}?)
	local id = buffer.readu8(buf, pos)

	pos += 1

	if id == EMPTY then
		return {}, pos
	end

	local returnedTab = {}

	local existingIndex = parExisting and parExisting.Index or 1
	local existing = parExisting and parExisting.Data or {  -- MASSIVE TABLE
		[0] = returnedTab
	}
	if not parExisting then
		parExisting = {Data = existing, Index = existingIndex}
	end

	local hasArray = id == ARRAY or id == TABLE

	if id ~= ARRAY and id ~= TABLE and id ~= DICT then
		return nil, pos -- data corruption
	end

	if hasArray then
		local index = 0
		while true do
			local valId = buffer.readu8(buf, pos)

			pos += 1
			if valId == ARRAY_END then
				break -- if there is no end, it will error!
			end
			if valId == TABLE_END then
				parExisting.Index = existingIndex
				return returnedTab, pos + 1 -- for ARRAY
			end

			index += 1
			if valId == 0 then
				continue
			end

			-- check if existing
			if valId == EQ_EXISTING then
				local value = existing[buffer.readu16(buf, pos)]
				if value == nil then
					parExisting.Index = existingIndex
					return nil, pos -- data corrupted
				end
				pos += 2
				returnedTab[index] = value
				continue
			end

			local value: any = nil
			local oldPos = pos
			if valId <= 2 then -- boolean
				value, pos = Boolean.deserialize(buf, pos)
			elseif valId <= 8 then -- buffer
				value, pos = Buffer.deserialize(buf, pos) 
			elseif valId <= 87 then -- string
				value, pos = String.deserialize(buf, pos)
			elseif valId <= 135 then -- number
				value, pos = Number.deserialize(buf, pos)
			elseif valId <= 193 then -- vector
				value, pos = Vector.deserialize(buf, pos)
			elseif valId <= 201 then -- table
				parExisting.Index = existingIndex
				value, pos = tabDeserialize(buf, pos, parExisting)
				existingIndex = parExisting.Index
			elseif valId <= 223 then -- userdata
				value, pos = Userdata.deserialize(buf, data)
			else 
				pos += 1 -- ... data corrupted
			end

			if value == nil then
				parExisting.Index = existingIndex
				return nil, pos -- data corrupted
			end

			if pos - 1 > oldPos then
				existing[existingIndex] = value
				existingIndex += 1
			end

			returnedTab[index] = value
		end
	end

	while true do
		local valId = buffer.readu8(buf, pos)
		pos += 1
		if valId == TABLE_END then
			parExisting.Index = existingIndex
			return returnedTab, pos
		end

		local key, value

		-- check if existing
		if valId == EQ_EXISTING then
			key = existing[buffer.readu16(buf, pos)]
			if key == nil then
				parExisting.Index = existingIndex
				return nil, pos -- data corrupted
			end
			pos += 2
		end
		
		local oldPos = pos
		
		if key == nil then
			if valId <= 2 then -- boolean
				key, pos = Boolean.deserialize(buf, pos)
			elseif valId <= 8 then -- buffer
				key, pos = Buffer.deserialize(buf, pos) 
			elseif valId <= 87 then -- string
				key, pos = String.deserialize(buf, pos)
			elseif valId <= 135 then -- number
				key, pos = Number.deserialize(buf, pos)
			elseif valId <= 193 then -- vector
				key, pos = Vector.deserialize(buf, pos)
			elseif valId <= 201 then -- table
				parExisting.Index = existingIndex
				key, pos = tabDeserialize(buf, pos, parExisting)
				existingIndex = parExisting.Index
			elseif valId <= 223 then -- userdata
				key, pos = Userdata.deserialize(buf, pos)
			else 
				pos += 1 -- ... data corrupted
			end

			if key == nil then
				parExisting.Index = existingIndex
				return nil, pos -- data corrupted
			end
		end

		if pos - 1 > oldPos then
			existing[existingIndex] = key
			existingIndex += 1
		end

		valId = buffer.readu8(buf, pos)
		pos += 1

		-- check if existing
		if valId == EQ_EXISTING then
			value = existing[buffer.readu16(buf, pos)]
			if value == nil then
				parExisting.Index = existingIndex
				return nil, pos -- data corrupted
			end
			pos += 3
		end
		
		local oldPos = pos
		
		if value == nil then
			if valId <= 2 then -- boolean
				value, pos = Boolean.deserialize(buf, pos)
			elseif valId <= 8 then -- buffer
				value, pos = Buffer.deserialize(buf, pos) 
			elseif valId <= 87 then -- string
				value, pos = String.deserialize(buf, pos)
			elseif valId <= 135 then -- number
				value, pos = Number.deserialize(buf, pos)
			elseif valId <= 193 then -- vector
				value, pos = Vector.deserialize(buf, pos)
			elseif valId <= 201 then -- table
				parExisting.Index = existingIndex
				value, pos = tabDeserialize(buf, pos, parExisting)
				existingIndex = parExisting.Index
			elseif valId <= 223 then -- userdata
				value, pos = Userdata.deserialize(buf, pos)
			else 
				pos += 1 -- ... data corrupted
			end

			if value == nil then
				parExisting.Index = existingIndex
				return nil, pos -- data corrupted
			end
		end

		if pos - 1 > oldPos then
			existing[existingIndex] = value
			existingIndex += 1
		end

		returnedTab[key] = value
	end
end

return {
	serialize = tabSerialize,
	deserialize = tabDeserialize,
}
