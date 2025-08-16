--!optimize 2
--!strict
local inflate = require("./inflate")

-- all
local serialSwitch = {
	boolean = require("./boolean").serialize,
	buffer = require("./buffer").serialize,
	string = require("./string").serialize,
	number = require("./number").serialize,
	vector = require("./vector").serialize,
	userdata = require("./userdata").serialize
}

local nilSerializer = require("./nil").serialize

local boolDeserializer = require("./boolean").deserialize
local bufDeserializer = require("./buffer").deserialize
local strDeserializer = require("./string").deserialize
local numDeserializer = require("./number").deserialize
local vecDeserializer = require("./vector").deserialize
local userDeserializer = require("./userdata").deserialize

local EMPTY = 194
local TABLE = 195
local EQ_EXISTING = 196
local ARRAY = 197
local DICT = 198
local ARRAY_END = 199
local TABLE_END = 200

@native
function tabSerializer(value: {[any]: any}, buf: buffer, pos: number, size: number)
	
	local existingIndex = 1
	local existing = {[value] = 0}
	local roundRobinCache = {}
	local roundRobinLength = 0
	local roundRobinIndex = 61440
	
	local constants = {}
	
	local serialTable
	
	buf, size = buffer.create(64), 64
	
	@native
	local function serialCache(data: any, typeName: string?)
		local typeV = typeName or type(data)
		local oldPos = pos
		
		local case = serialSwitch[typeV]
		if case then
			buf, pos, size = case(data, buf, pos, size)
		else
			-- could be table (or function or thread for array)
			if typeV == "function" or typeV == "thread" then
				buf, pos, size = nilSerializer(data, buf, pos, size)
			else
				-- ISSUE: A table cycle may be so deep that it bypasses existing altogether
				-- We will need to ensure the cycle is nonproblematic
				if existingIndex < 61_440 then
					existing[data] = existingIndex
					existingIndex += 1
				end
				
				serialTable(data)
				return
			end
		end
	
		if pos - oldPos == 1 then
			constants[data] = buffer.readu8(buf, oldPos)
		elseif pos - oldPos == 2 then
			constants[data] = buffer.readu16(buf, oldPos)
		elseif data == data then
			if existingIndex < 61_440 then
				-- cache for rest (only 61_440 values we can cache!!)
				-- for duration of table
				-- data == data checks for nans :>
				existing[data] = existingIndex
				existingIndex += 1
				return
			end
			-- Not done, it is hard to find datasets for this
			-- 4096 values we cache in a cycle
			if roundRobinLength == 4096 then
				if roundRobinIndex == 65_536 then
					roundRobinIndex = 61_440
				end
				-- Cycle time
				existing[roundRobinCache[roundRobinIndex - 61_439]] = nil
				existing[data] = roundRobinIndex
				roundRobinCache[roundRobinIndex] = data
				roundRobinIndex += 1
				return
			end
			existing[data] = 61_440 + roundRobinLength
			roundRobinLength += 1
			roundRobinCache[roundRobinLength] = data
		end
	end
	
	@native
	function serialTable(data: {[any]: any})
		local isDict = #data == 0
		if pos + 1 > size then
			buf, size = inflate(buf, pos + 1, size)
		end
		buffer.writeu8(buf, pos, if isDict then DICT else TABLE)
		
		pos += 1
		
		local oldPos = pos
		local endArray = false
		local lastIndex = 1
		
		for key, element in data do
			-- Array section
			if lastIndex == key then
				lastIndex += 1
				
				local cached = existing[element]
				if cached then
					if pos + 3 > size then
						buf, size = inflate(buf, pos + 3, size)
					end
					buffer.writeu8(buf, pos, EQ_EXISTING)
					buffer.writeu16(buf, pos + 1, cached)
					pos += 3
					continue
				end
				cached = constants[element]
				if cached then
					local newSize = cached > 255 and 2 or 1
					if pos + newSize > size then
						buf, size = inflate(buf, pos + newSize, size)
					end
					if newSize == 1 then
						buffer.writeu8(buf, pos, cached)
					else
						buffer.writeu16(buf, pos, cached)
					end
					pos += newSize
					continue
				end
				
				serialCache(element)
				continue
			end
			if not endArray and not isDict then
				endArray = true
				if pos + 1 > size then
					buf, size = inflate(buf, pos + 1, size)
				end
				buffer.writeu8(buf, pos, ARRAY_END)
				pos += 1
			end
			
			-- Dictionary section
			local typeKey = type(key)
			if typeKey == "function" or typeKey == "thread" then
				continue
			end
			
			local typeElement = type(element)
			if typeElement == "function" or typeElement == "thread" then
				continue
			end
			
			local cached = existing[key]
			if cached then
				if pos + 3 > size then
					buf, size = inflate(buf, pos + 3, size)
				end
				buffer.writeu8(buf, pos, EQ_EXISTING)
				buffer.writeu16(buf, pos + 1, cached)
				pos += 3
			end
			
			local constCached = constants[key]
			if constCached and not cached then
				local newSize = constCached > 255 and 2 or 1
				if pos + newSize > size then
					buf, size = inflate(buf, pos + newSize, size)
				end
				if newSize == 1 then
					buffer.writeu8(buf, pos, constCached)
				else
					buffer.writeu16(buf, pos, constCached)
				end
				pos += newSize
			elseif not cached then
				-- store key
				serialCache(key, typeKey)
			end
		
			cached = existing[element]
			if cached then
				if pos + 3 > size then
					buf, size = inflate(buf, pos + 3, size)
				end
				-- writebits is not faster
				buffer.writeu8(buf, pos, EQ_EXISTING)
				buffer.writeu16(buf, pos + 1, cached)
				pos += 3
				continue
			end
			cached = constants[element]
			if cached then
				local newSize = cached > 255 and 2 or 1
				if pos + newSize > size then
					buf, size = inflate(buf, pos + newSize, size)
				end
				if newSize == 1 then
					buffer.writeu8(buf, pos, cached)
				else
					buffer.writeu16(buf, pos, cached)
				end
				pos += newSize
				continue
			end
			
			-- store element
			serialCache(element, typeElement)
		end
		
		if oldPos == pos then
			buffer.writeu8(buf, pos - 1, EMPTY)
			existing[data] = nil
			existingIndex -= 1
			return
		end
		
		if not isDict and not endArray then
			buffer.writeu8(buf, oldPos - 1, ARRAY)
		end
		if pos + 1 > size then
			buf, size = inflate(buf, pos + 1, size)
		end
		buffer.writeu8(buf, pos, TABLE_END)
		pos += 1
	end
	
	serialTable(value)	
	
	table.clear(existing)
	if roundRobinLength > 0 then
		table.clear(roundRobinCache)
	end
	table.clear(constants)
	
	return buf, pos, size
end


@native
function tabDeserializer(buf: buffer, pos: number)
	
	local returnedTab = {}
	
	local existingIndex = 1
	local existing = {[0] = returnedTab}
	local roundRobinIndex = 61440
		
	local deserialTable
	
	@native
	local function deserialCache(valId: number): any
		local value: any = nil
		local oldPos = pos
		if valId <= 2 then -- boolean
			value, pos = boolDeserializer(buf, pos)
		elseif valId <= 8 then -- buffer
			value, pos = bufDeserializer(buf, pos) 
		elseif valId <= 87 then -- string
			value, pos = strDeserializer(buf, pos)
		elseif valId <= 135 then -- number
			value, pos = numDeserializer(buf, pos)
		elseif valId <= 193 then -- vector
			value, pos = vecDeserializer(buf, pos)
		elseif valId <= 201 then -- table
			-- TODO: Maybe add cyclic checker here?
			if existingIndex < 61_440 then
				existing[existingIndex] = value
				existingIndex += 1
			end
			return deserialTable()
		elseif valId <= 223 then -- userdata
			value, pos = userDeserializer(buf, pos)
		else 
			pos += 1 -- ... data corrupted
		end
		
		if value == nil then
			return nil -- data corrupted
		end
		
		if pos - 2 > oldPos then
			if existingIndex < 61_440 then
				existing[existingIndex] = value
				existingIndex += 1
				return value
			end
			-- TODO: roundRobin stuff
			if roundRobinIndex == 65_536 then
				roundRobinIndex = 61_440
			end
			-- Cycle time
			existing[roundRobinIndex] = value
			roundRobinIndex += 1			
		end
		return value
	end
	
	@native
	function deserialTable(data: {[any]: any}?): {[any]: any}?
		local id = buffer.readu8(buf, pos)
		
		pos += 1
		
		if id == EMPTY then
			existing[existingIndex - 1] = nil
			existingIndex -= 1
			return {}
		end
		
		data = data or {}
		
		local hasArray = id == ARRAY or id == TABLE
		
		if not hasArray and id ~= DICT then
			return nil -- data corruption
		end
		
		if hasArray then
			local index = 0
			while true do
				local valId = buffer.readu8(buf, pos)
				
				if valId == ARRAY_END then
					pos += 1
					break -- if there is no end, it will error!
				end
				if valId == TABLE_END then
					pos += 1
					return data -- for ARRAY
				end
				
				index += 1
				if valId == 0 then
					pos += 1
					continue
				end
				
				local value
				
				-- check if existing
				if valId == EQ_EXISTING then
					value = existing[buffer.readu16(buf, pos + 1)]
					pos += 3
					if value == nil then
						return nil
					end
					data[index] = value
					continue
				end
				
				value = deserialCache(valId)
				if value == nil then
					return nil
				end
				data[index] = value
			end
		end
		
		while true do
			local valId = buffer.readu8(buf, pos)
			if valId == TABLE_END then
				pos += 1
				return data
			end
			
			local key, value
			
			-- check if existing
			if valId == EQ_EXISTING then
				key = existing[buffer.readu16(buf, pos + 1)]
				if key == nil then
					return nil
				end
				pos += 3
			end
			
			if not key then
				key = deserialCache(valId)
				if key == nil then
					return nil
				end
			end
			
			valId = buffer.readu8(buf, pos)
			
			-- check if existing
			if valId == EQ_EXISTING then
				value = existing[buffer.readu16(buf, pos + 1)]
				if value == nil then
					return nil
				end
				pos += 3
				data[key] = value
				continue
			end
			
			value = deserialCache(valId)
			if value == nil then
				return nil
			end
			
			data[key] = value
		end
	end
	
	local data = deserialTable(returnedTab)
	
	table.clear(existing)
	
	return data, pos + 1
end

return {
	serialize = tabSerializer,
	deserialize = tabDeserializer,
}
