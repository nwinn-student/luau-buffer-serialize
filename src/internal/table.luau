--!optimize 2
local enumerator = require("./pointer/Enumerator")

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

local nilDeserializer = require("./nil").deserialize
local boolDeserializer = require("./boolean").deserialize
local bufDeserializer = require("./buffer").deserialize
local strDeserializer = require("./string").deserialize
local numDeserializer = require("./number").deserialize
local vecDeserializer = require("./vector").deserialize
local userDeserializer = require("./userdata").deserialize

local inflate = enumerator.Methods.inflateBuffer

enumerator = nil

local EMPTY = 194
local TABLE = 195
local EQ_EXISTING = 196
local ARRAY = 197
local DICT = 198
local ARRAY_END = 199
local TABLE_END = 200
local EQ_TINY = 201

type ExistingData = {
	Data: {[any]: number},
	Tiny: {[any]: number},
	Index: number,
	TinyIndex: number,
	One: {[any]: number}?,
	Two: {[any]: number}?
}

@native
local function serialCache(data: any, buf: buffer, pos: number, size: number, existing: ExistingData, existingIndex: number)
	-- check 1 and 2 byte caches
	local cached = existing.Two[data]
	if cached then
		if pos + 2 > size then
			buf, size = inflate(buf, pos + 2, size)
		end
		buffer.writeu16(buf, pos, cached)
		return buf, pos + 2, size, existingIndex
	end
	cached = existing.One[data]
	if cached then
		if pos + 1 > size then
			buf, size = inflate(buf, pos + 1, size)
		end
		buffer.writeu8(buf, pos, cached)
		return buf, pos + 1, size, existingIndex
	end
	
	local typeV = type(data)
	local oldPos = pos
	
	local case = serialSwitch[typeV]
	if case then
		buf, pos, size = case(data, buf, pos, size)
	else
		-- could be table (or function or thread for array)
		if typeV == "function" or typeV == "thread" then
			buf, pos, size = nilSerializer(data, buf, pos, size)
		else
			existing.Index = existingIndex
			buf, pos, size = tabSerializer(data, buf, pos, size, existing)
			existingIndex = existing.Index
		end
	end
	
	if pos - oldPos == 1 then
		existing.One[data] = buffer.readu8(buf, oldPos)
	elseif pos - oldPos == 2 then
		existing.Two[data] = buffer.readu16(buf, oldPos)
	elseif data == data then
		if existingIndex ~= 65_535 then
			-- cache for rest (only 65_536 values we can cache!!)
			-- v == v checks for nans :>
			existing.Data[data] = existingIndex
			existingIndex += 1
		end
		local tinyIndex = existing.TinyIndex
		if tinyIndex + 1 == 256 then
			table.clear(existing.Tiny)
			tinyIndex = 0
		end
		existing.Tiny[data] = tinyIndex
		existing.TinyIndex = tinyIndex + 1
	end
	return buf, pos, size, existingIndex
end

@native
function tabSerializer(value: {[any]: any}, buf: buffer, pos: number, size: number, parExisting: ExistingData?)

	local lastIndex = 1
	local isFinal = not parExisting
	if isFinal then
		parExisting = {
			-- 2^16 values
			Data = {[value] = 0},
			-- 2^8 values
			Tiny = {},
			Index = 1,
			TinyIndex = 0,
			-- A slower fast-path
			One = {},
			Two = {}
		}
	end
	
	local existingIndex = parExisting.Index
	local existing = parExisting.Data
	local tiny = parExisting.Tiny
	
	local isDict = #value == 0
	if not buf then
		buf, size = buffer.create(64), 64
	elseif pos + 1 > size then
		buf, size = inflate(buf, pos + 1, size)
	end
	buffer.writeu8(buf, pos, if isDict then DICT else TABLE)
	
	local tempPos = pos + 1
	local endArray = false
	
	for i,v in value do
		-- Array portion
		if lastIndex == i then
			lastIndex += 1
			
			local cached = tiny[v]
			if cached then
				if tempPos + 2 > size then
					buf, size = inflate(buf, tempPos + 2, size)
				end
				buffer.writeu8(buf, tempPos, EQ_TINY)
				buffer.writeu8(buf, tempPos + 1, cached)
				tempPos += 2
				continue
			end
			cached = existing[v]
			if cached then
				if tempPos + 3 > size then
					buf, size = inflate(buf, tempPos + 3, size)
				end
				-- writebits is not faster
				buffer.writeu8(buf, tempPos, EQ_EXISTING)
				buffer.writeu16(buf, tempPos + 1, cached)
				tempPos += 3
				continue
			end
			
			buf, tempPos, size, existingIndex = serialCache(v, buf, tempPos, size, parExisting, existingIndex)
			continue
		end
		if not endArray and not isDict then
			endArray = true
			if tempPos + 1 > size then
				buf, size = inflate(buf, tempPos + 1, size)
			end
			buffer.writeu8(buf, tempPos, ARRAY_END)
			tempPos += 1
		end
		
		local typeI = type(i)
		if typeI == "function" or typeI == "thread" then
			continue
		end
		
		local typeV = type(v)
		if typeV == "function" or typeV == "thread" then
			continue
		end
		
		local cached = tiny[i]
		if cached then
			if tempPos + 2 > size then
				buf, size = inflate(buf, tempPos + 2, size)
			end
			buffer.writeu8(buf, tempPos, EQ_TINY)
			buffer.writeu8(buf, tempPos + 1, cached)
			tempPos += 2
		end
		local excached = existing[i]
		if excached and not cached then
			if tempPos + 3 > size then
				buf, size = inflate(buf, tempPos + 3, size)
			end
			-- writebits is not faster
			buffer.writeu8(buf, tempPos, EQ_EXISTING)
			buffer.writeu16(buf, tempPos + 1, excached)
			tempPos += 3
		elseif not cached then
			-- store i
			buf, tempPos, size, existingIndex = serialCache(i, buf, tempPos, size, parExisting, existingIndex)
		end
		
		local cached = tiny[v]
		if cached then
			if tempPos + 2 > size then
				buf, size = inflate(buf, tempPos + 2, size)
			end
			buffer.writeu8(buf, tempPos, EQ_TINY)
			buffer.writeu8(buf, tempPos + 1, cached)
			tempPos += 2
			continue
		end
		cached = existing[v]
		if cached then
			if tempPos + 3 > size then
				buf, size = inflate(buf, tempPos + 3, size)
			end
			-- writebits is not faster
			buffer.writeu8(buf, tempPos, EQ_EXISTING)
			buffer.writeu16(buf, tempPos + 1, cached)
			tempPos += 3
			continue
		end
		
		-- store v
		buf, tempPos, size, existingIndex = serialCache(v, buf, tempPos, size, parExisting, existingIndex)
	end
	
	if tempPos == pos + 1 then
		buffer.writeu8(buf, pos, EMPTY)
		return buf, pos + 1, size
	end
	
	if not isFinal then
		parExisting.Index = existingIndex
	else
		table.clear(existing)
		table.clear(tiny)
		table.clear(parExisting.One)
		table.clear(parExisting.Two)
	end
	
	if not isDict and not endArray then
		buffer.writeu8(buf, pos, ARRAY)
	end
	if tempPos + 1 > size then
		buf, size = inflate(buf, tempPos + 1, size)
	end
	buffer.writeu8(buf, tempPos, TABLE_END)
	return buf, tempPos + 1, size
end


local function deserialCache(valId, buf, pos, existing, existingIndex)
	-- check if tiny
	if valId == EQ_TINY then
		local value = existing.Tiny[buffer.readu8(buf, pos + 1)]
		if value == nil then
			return nil, pos + 1, existingIndex -- data corrupted
		end
		return value, pos + 2, existingIndex
	end
	-- check if existing
	if valId == EQ_EXISTING then
		local value = existing.Data[buffer.readu16(buf, pos + 1)]
		if value == nil then
			return nil, pos + 1, existingIndex -- data corrupted
		end
		return value, pos + 3, existingIndex
	end
	
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
		existing.Index = existingIndex
		value, pos = tabDeserializer(buf, pos, existing)
		existingIndex = existing.Index
	elseif valId <= 223 then -- userdata
		value, pos = userDeserializer(buf, pos)
	else 
		pos += 1 -- ... data corrupted
	end
	
	if value == nil then
		existing.Index = existingIndex
		return nil, pos -- data corrupted
	end
	
	if pos - 1 > oldPos then
		if existingIndex ~= 65_535 then
			existing.Data[existingIndex] = value
			existingIndex += 1
		end
		local tinyIndex = existing.TinyIndex
		if tinyIndex + 1 == 256 then
			table.clear(existing.Tiny)
			tinyIndex = 0
		end
		existing.Tiny[tinyIndex] = value
		existing.TinyIndex = tinyIndex + 1
	end
	return value, pos, existingIndex
end

type DexistingData = {
	Data: {[number]: any},
	Tiny: {[number]: any},
	Index: number,
	TinyIndex: number
}

@native
function tabDeserializer(buf: buffer, pos: number, parExisting: DexistingData?)
	local id = buffer.readu8(buf, pos)
	
	pos += 1
	
	if id == EMPTY then
		return {}, pos
	end
	
	local returnedTab = {}
	
	local isFinal = not parExisting
	local close
	if isFinal then
		parExisting = {
			Data = {[0] = returnedTab},
			Tiny = {},
			Index = 1,
			TinyIndex = 0
		}
		
		-- Ensures memory leaks are avoided
		close = function()
			table.clear(parExisting.Data)
			table.clear(parExisting.Tiny)
		end
	end
	
	local existingIndex = parExisting.Index
	
	local hasArray = id == ARRAY or id == TABLE
	
	if id ~= ARRAY and id ~= TABLE and id ~= DICT then
		if isFinal then close() end
		return nil, pos -- data corruption
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
				parExisting.Index = existingIndex
				if isFinal then close() end
				return returnedTab, pos + 1 -- for ARRAY
			end
			
			index += 1
			if valId == 0 then
				pos += 1
				continue
			end
			
			local value
			value, pos, existingIndex = deserialCache(valId, buf, pos, parExisting, existingIndex)
			if value == nil then
				if isFinal then close() end
				return nil, pos
			end
			returnedTab[index] = value
		end
	end
	
	while true do
		local valId = buffer.readu8(buf, pos)
		if valId == TABLE_END then
			parExisting.Index = existingIndex
			if isFinal then close() end
			return returnedTab, pos + 1
		end
		
		local key, value
		key, pos, existingIndex = deserialCache(valId, buf, pos, parExisting, existingIndex)
		if key == nil then
			if isFinal then close() end
			return nil, pos
		end
		valId = buffer.readu8(buf, pos)
		value, pos, existingIndex = deserialCache(valId, buf, pos, parExisting, existingIndex)
		if value == nil then
			if isFinal then close() end
			return nil, pos
		end
		
		returnedTab[key] = value
	end
end

return {
	serialize = tabSerializer,
	deserialize = tabDeserializer,
}
