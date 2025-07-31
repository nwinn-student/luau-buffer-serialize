--!optimize 2
local enumerator = require("./pointer/Enumerator")
type BufferData = enumerator.BufferData
type PositionData = enumerator.PositionData

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
local function tabSerialize(value: {[any]: any}, data: BufferData, parExisting: {Data: {[any]:any}, Index: number}?)
	local buf = data.Data
	local pos = data.Position or 0

	if next(value) == nil then
		buf = grow(buf, data, 1)
		buffer.writeu8(buf, pos, EMPTY)
		return
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
	buf = grow(buf, data, 1) -- 1 to say table
	buffer.writeu8(buf, pos, if isDict then DICT else TABLE)
	
	local tempPos = pos + 1
	local endArray = false
	
	for i,v in value do
		print(existing)
		lastIndex += 1
		local isInArray = lastIndex == i

		if isInArray then
			-- fast paths
			local cached = existing[v]
			if cached then
				buf = grow(buf, data, 3)
				buffer.writeu8(buf, tempPos, EQ_EXISTING)
				buffer.writeu16(buf, tempPos + 1, cached)
				tempPos += 3
				continue
			end
			-- check 1 and 2 byte caches
			cached = two_byte_existing[v]
			if cached then
				buf = grow(buf, data, 2)
				buffer.writeu16(buf, tempPos, cached)
				tempPos += 2
				continue
			end
			cached = one_byte_existing[v]
			if cached then
				buf = grow(buf, data, 1)
				buffer.writeu8(buf, tempPos, cached)
				tempPos += 1
				continue
			end

			local typeV = type(v)
			if typeV == "nil" or typeV == "function" or typeV == "thread" then
				Nil.serialize(v, data)
			elseif typeV == "boolean" then
				Boolean.serialize(v, data)
			elseif typeV == "buffer" then
				Buffer.serialize(v, data)
			elseif typeV == "string" then
				String.serialize(v, data)
			elseif typeV == "number" then
				Number.serialize(v, data)
			elseif typeV == "vector" then
				Vector.serialize(v, data)
			elseif typeV == "userdata" then
				Userdata.serialize(v, data)
			elseif typeV == "table" then
				parExisting.Index = existingIndex
				tabSerialize(v, data, parExisting)
				existingIndex = parExisting.Index
			end
			buf = data.Data

			local ttp = data.Position
			if ttp - tempPos == 1 then
				one_byte_existing[v] = buffer.readu8(buf, tempPos)
			elseif ttp - tempPos == 2 then
				two_byte_existing[v] = buffer.readu16(buf, tempPos)
			else
				-- cache for rest
				existing[v] = existingIndex
				existingIndex += 1
			end
			tempPos = ttp
			continue
		end
		if not endArray and not isDict then
			endArray = true
			buf = grow(buf, data, 1)
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
			buf = grow(buf, data, 3)
			buffer.writeu8(buf, tempPos, EQ_EXISTING)
			buffer.writeu16(buf, tempPos + 1, keyCached)
			tempPos += 3
		end
		-- check 1 and 2 byte caches
		local twoKeyCached = not keyCached and two_byte_existing[i]
		if twoKeyCached then
			buf = grow(buf, data, 2)
			buffer.writeu16(buf, tempPos, twoKeyCached)
			tempPos += 2
		end
		local threeKeyCached = not keyCached and not twoKeyCached and one_byte_existing[i]
		if threeKeyCached then
			buf = grow(buf, data, 1)
			buffer.writeu8(buf, tempPos, threeKeyCached)
			tempPos += 1
		end
		
		-- store i
		if not keyCached and not twoKeyCached and not threeKeyCached then
			if typeI == "boolean" then
				Boolean.serialize(i, data)
			elseif typeI == "buffer" then
				Buffer.serialize(i, data)
			elseif typeI == "string" then
				String.serialize(i, data)
			elseif typeI == "number" then
				Number.serialize(i, data)
			elseif typeI == "vector" then
				Vector.serialize(i, data)
			elseif typeI == "userdata" then
				Userdata.serialize(i, data)
			elseif typeI == "table" then
				parExisting.Index = existingIndex
				tabSerialize(i, data, parExisting)
				existingIndex = parExisting.Index
			end
			buf = data.Data
			
			local ttp = data.Position
			if ttp - tempPos == 1 then
				one_byte_existing[i] = buffer.readu8(buf, tempPos)
			elseif ttp - tempPos == 2 then
				two_byte_existing[i] = buffer.readu16(buf, tempPos)
			else
				-- cache for rest
				existing[i] = existingIndex
				existingIndex += 1
			end
			tempPos = ttp
		end
		
		local valueCached = existing[v]
		if valueCached then
			buf = grow(buf, data, 3)
			buffer.writeu8(buf, tempPos, EQ_EXISTING)
			buffer.writeu16(buf, tempPos + 1, valueCached)
			tempPos += 3
			continue
		end
		-- check 1 and 2 byte caches
		valueCached = two_byte_existing[v]
		if valueCached then
			buf = grow(buf, data, 2)
			buffer.writeu16(buf, tempPos, valueCached)
			tempPos += 2
			continue
		end
		valueCached = one_byte_existing[v]
		if valueCached then
			buf = grow(buf, data, 1)
			buffer.writeu8(buf, tempPos, valueCached)
			tempPos += 1
			continue
		end
		
		-- store v
		if typeV == "boolean" then
			Boolean.serialize(v, data)
		elseif typeV == "buffer" then
			Buffer.serialize(v, data)
		elseif typeV == "string" then
			String.serialize(v, data)
		elseif typeV == "number" then
			Number.serialize(v, data)
		elseif typeV == "vector" then
			Vector.serialize(v, data)
		elseif typeV == "userdata" then
			Userdata.serialize(v, data)
		elseif typeV == "table" then
			parExisting.Index = existingIndex
			tabSerialize(v, data, parExisting)
			existingIndex = parExisting.Index
		end
		buf = data.Data

		local ttp = data.Position
		if ttp - tempPos == 1 then
			one_byte_existing[v] = buffer.readu8(buf, tempPos)
		elseif ttp - tempPos == 2 then
			two_byte_existing[v] = buffer.readu16(buf, tempPos)
		else
			-- cache for rest
			existing[v] = existingIndex
			existingIndex += 1 -- ??
		end
		tempPos = ttp
	end
	
	if not isDict or endArray then
		buffer.writeu8(buf, pos, ARRAY)
	end
	buf = grow(buf, data, 1)
	buffer.writeu8(buf, tempPos, TABLE_END)
end

@native
local function tabDeserialize(buf: buffer, data: PositionData, parExisting: {Data: {[any]:any}, Index: number}?)
	local pos = data.Position
	local id = buffer.readu8(buf, pos)
	
	data.Position += 1
	pos += 1
	
	if id == EMPTY then
		return {}
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
		return nil -- data corruption
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
				data.Position += 1
				return returnedTab -- for ARRAY
			end
			
			index += 1
			if valId == 0 then
				data.Position += 1 -- I don't wanna bother calling nil
				continue
			end
			
			-- check if existing
			if valId == EQ_EXISTING then
				data.Position += 1
				local value = existing[buffer.readu16(buf, pos)]
				if value == nil then
					return nil -- data corrupted
				end
				pos += 2
				data.Position += 2 -- ??
				returnedTab[index] = value
				continue
			end
			
			local value: any = nil
			if valId <= 2 then -- boolean
				value = Boolean.deserialize(buf, data)
			elseif valId <= 8 then -- buffer
				value = Buffer.deserialize(buf, data) 
			elseif valId <= 87 then -- string
				value = String.deserialize(buf, data)
			elseif valId <= 135 then -- number
				value = Number.deserialize(buf, data)
			elseif valId <= 193 then -- vector
				value = Vector.deserialize(buf, data)
			elseif valId <= 201 then -- table
				parExisting.Index = existingIndex
				value = tabDeserialize(buf, data, parExisting)
				existingIndex = parExisting.Index
			elseif valId <= 223 then -- userdata
				value = Userdata.deserialize(buf, data)
			else 
				data.Position += 1 -- ... data corrupted
			end
			
			if value == nil then
				return nil -- data corrupted
			end
						
			-- add to existing if pos changed 3+ bytes
			local newPos = data.Position
			
			if newPos - 1 > pos then
				existing[existingIndex] = value
				existingIndex += 1
			end
			
			pos = newPos
			returnedTab[index] = value
		end
		data.Position = pos -- ??
	end
	
	while true do
		print(existing)
		local valId = buffer.readu8(buf, pos)
		pos += 1
		if valId == TABLE_END then
			data.Position += 1
			return returnedTab
		end
		
		local key, value
		
		-- check if existing
		if valId == EQ_EXISTING then
			data.Position += 1
			key = existing[buffer.readu16(buf, pos)]
			if key == nil then
				return nil -- data corrupted
			end
			pos += 2
			data.Position += 2 -- ??
		end
		if key == nil then
			if valId <= 2 then -- boolean
				key = Boolean.deserialize(buf, data)
			elseif valId <= 8 then -- buffer
				key = Buffer.deserialize(buf, data) 
			elseif valId <= 87 then -- string
				key = String.deserialize(buf, data)
			elseif valId <= 135 then -- number
				key = Number.deserialize(buf, data)
			elseif valId <= 193 then -- vector
				key = Vector.deserialize(buf, data)
			elseif valId <= 201 then -- table
				parExisting.Index = existingIndex
				key = tabDeserialize(buf, data, parExisting)
				existingIndex = parExisting.Index
			elseif valId <= 223 then -- userdata
				key = Userdata.deserialize(buf, data)
			else 
				data.Position += 1 -- ... data corrupted
			end
			
			if key == nil then
				return nil -- data corrupted
			end
		end
		
		-- add to existing if pos changed 3+ bytes
		local newPos = data.Position
		
		if newPos - 1 > pos then
			print(newPos, pos, key)
			existing[existingIndex] = key
			existingIndex += 1
		end
		
		pos = newPos
		valId = buffer.readu8(buf, pos)
		pos += 1
		
		-- check if existing
		if valId == EQ_EXISTING then
			data.Position += 1
			value = existing[buffer.readu16(buf, pos)]
			if value == nil then
				return nil -- data corrupted
			end
			pos += 3
			data.Position += 2 -- ??
		end
		if value == nil then
			if valId <= 2 then -- boolean
				value = Boolean.deserialize(buf, data)
			elseif valId <= 8 then -- buffer
				value = Buffer.deserialize(buf, data) 
			elseif valId <= 87 then -- string
				value = String.deserialize(buf, data)
			elseif valId <= 135 then -- number
				value = Number.deserialize(buf, data)
			elseif valId <= 193 then -- vector
				value = Vector.deserialize(buf, data)
			elseif valId <= 201 then -- table
				value = tabDeserialize(buf, data, parExisting)
			elseif valId <= 223 then -- userdata
				value = Userdata.deserialize(buf, data)
			else 
				data.Position += 1 -- ... data corrupted
			end
			
			if value == nil then
				return nil -- data corrupted
			end
		end
		
		-- add to existing if pos changed 3+ bytes
		newPos = data.Position
		
		if newPos - 1 > pos then
			existing[existingIndex] = value
			existingIndex += 1
		end
		
		pos = newPos
		returnedTab[key] = value
	end
end

return {
	serialize = tabSerialize,
	deserialize = tabDeserialize,
}
