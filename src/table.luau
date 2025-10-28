--!optimize 2
--!strict
local inflate = require("./inflate")
local link = require("./link")
local linkValues = link.values :: { [any]: any }
local linkSer = link.serialize
local linkType = link.type
local isLink = link.islink
local isDuo = link.isduo

type Serialize = (
	data: any,
	buf: buffer,
	pos: number,
	size: number
) -> (buffer, number, number)

type Deserialize = (buf: buffer, pos: number) -> (any, number)

type Switch<VAR, F> = {
	[VAR]: F,
}

local strSer = require("./string").serialize
local numSer = require("./number").serialize
local vecSer = require("./vector").serialize
local userSer = require("./userdata").serialize

local serialSwitch: Switch<string, Serialize> = table.freeze({
	boolean = require("./boolean").serialize,
	buffer = require("./buffer").serialize,
	string = @native function(data: any, buf: buffer, pos: number, size: number)
		local linkId = linkValues[data]
		if linkId then
			return linkSer(linkId, buf, pos, size)
		end
		return strSer(data, buf, pos, size)
	end,
	number = @native function(data: any, buf: buffer, pos: number, size: number)
		local linkId = linkValues[data]
		if linkId then
			return linkSer(linkId, buf, pos, size)
		end
		return numSer(data, buf, pos, size)
	end,
	vector = @native function(data: any, buf: buffer, pos: number, size: number)
		local linkId = linkValues[data]
		if linkId then
			return linkSer(linkId, buf, pos, size)
		end
		return vecSer(data, buf, pos, size)
	end,
	userdata = @native function(data: any, buf: buffer, pos: number, size: number)
		local linkId = linkValues[data]
		if linkId then
			return linkSer(linkId, buf, pos, size)
		end
		return userSer(data, buf, pos, size)
	end,
}) :: Switch<string, Serialize>
local unlinkedSwitch: Switch<string, Serialize> = {
	string = strSer,
	number = numSer,
	vector = vecSer,
	userdata = userSer,
}

local deserialSwitch: Switch<string, Deserialize> =
	table.freeze({
		boolean = require("./boolean").deserialize,
		buffer = require("./buffer").deserialize,
		string = require("./string").deserialize,
		number = require("./number").deserialize,
		vector = require("./vector").deserialize,
		userdata = require("./userdata").deserialize,
	}) :: Switch<string, Deserialize>

local EMPTY = 194
local TABLE = 195
local EQ_EXISTING = 196
local ARRAY = 197
local DICT = 198
local ARRAY_END = 199
local TABLE_END = 200

function tabSerializer(
	value: { [any]: any },
	buf: buffer,
	pos: number,
	size: number
)
	do
		local isEmpty = true
		for _, _ in value do
			isEmpty = false
			break
		end
		if isEmpty then
			buf, size = buffer.create(1), 1
			buffer.writeu8(buf, 0, EMPTY)
			return buf, 1, 1
		end
	end

	local existingIndex = 1
	local existing: { [any]: number } = { [value] = 0 }
	local roundRobinCache: { [number]: any } = {}
	local roundRobinLength = 0
	local roundRobinIndex = 61440

	local constants: { [any]: number } = {}

	local serialTable: (data: { [any]: any }) -> ()

	buf, size = buffer.create(64), 64

	@native
	local function existingCache(data: any)
		if existingIndex < 61_440 then
			-- cache for rest (only 61_440 values we can cache!!)
			-- for duration of table
			-- data == data checks for nans :>
			existing[data] = existingIndex
			existingIndex += 1
			return
		end
		-- TODO: Verify validity w/ larger datasets
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

	@native
	local function serialCache(data: any, typeName: string)
		if typeName == "table" then
			-- ISSUE: A table cycle may be so deep that it bypasses existing altogether
			-- We will need to ensure the cycle is nonproblematic
			-- Currently: Assumed improbable

			do
				local isEmpty = true
				for _, _ in data :: { [any]: any } do
					isEmpty = false
					break
				end
				if isEmpty then
					if pos + 1 > size then
						buf, size = inflate(buf, pos + 1, size)
					end
					buffer.writeu8(buf, pos, EMPTY)
					pos += 1
					return
				end
			end

			existingCache(data)

			serialTable(data)
			return
		end

		local oldPos, pairedId = pos, nil
		buf, pos, size, pairedId = serialSwitch[typeName](data, buf, pos, size)

		if pos - oldPos == 1 then
			if pairedId then
				constants[data] = pairedId
				buf, pos, size = unlinkedSwitch[typeName](data, buf, pos, size)
				return
			end

			local serValue = buffer.readu8(buf, oldPos)
			constants[data] = serValue
		elseif pos - oldPos == 2 then
			if pairedId then
				constants[data] = pairedId
				buf, pos, size = unlinkedSwitch[typeName](data, buf, pos, size)
				return
			end

			local serValue = buffer.readu16(buf, oldPos)
			constants[data] = serValue
		elseif data == data then
			existingCache(data)
		end
	end

	@native
	function serialTable(data: { [any]: any })
		local isDict = #data == 0
		if pos + 1 > size then
			buf, size = inflate(buf, pos + 1, size)
		end

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
					buf, pos, size = linkSer(cached, buf, pos, size)
					continue
				end

				local typeElement = type(element)

				if typeElement == "function" or typeElement == "thread" then
					constants[element] = 0 -- NIL
					pos += 1
					continue
				end

				serialCache(element, typeElement)
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
				buf, pos, size = linkSer(constCached, buf, pos, size)
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
				buf, pos, size = linkSer(cached, buf, pos, size)
				continue
			end

			-- store element
			serialCache(element, typeElement)
		end

		if isDict then
			buffer.writeu8(buf, oldPos - 1, DICT)
		else
			buffer.writeu8(buf, oldPos - 1, if not endArray then ARRAY else TABLE)
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

function tabDeserializer(buf: buffer, pos: number)
	local returnedTab = {}

	if buffer.readu8(buf, pos) == EMPTY then
		return returnedTab, 1
	end

	local existingIndex = 1
	local existing: { any } = { [0] = returnedTab }
	local roundRobinIndex = 61_440
	local paired = {}

	local deserialTable: (data: { [any]: any }) -> { [any]: any }

	@native
	local function existingCache(data: any)
		if existingIndex < 61_440 then
			existing[existingIndex] = data
			existingIndex += 1
			return
		end
		-- TODO: roundRobin stuff
		if roundRobinIndex == 65_536 then
			roundRobinIndex = 61_440
		end
		-- Cycle time
		existing[roundRobinIndex] = data
		roundRobinIndex += 1
	end

	@native
	local function deserialCache(valId: number): unknown
		if valId == EMPTY then
			pos += 1
			return {}
		elseif valId == TABLE or valId == ARRAY or valId == DICT then
			local value = {}
			existingCache(value)
			return deserialTable(value)
		end

		local value: any = nil
		local oldPos = pos
		local case = linkType(valId)

		if isLink(valId, case) then
			local isTwo = isDuo(valId, case)

			local pairedValue = paired[valId]
			if pairedValue then
				pos += if isTwo then 2 else 1
				return pairedValue
			end

			-- read id, then skip to value
			if isTwo then
				local id = buffer.readu16(buf, pos)
				value, pos = deserialSwitch[case](buf, pos + 2)
				paired[id] = value
				return value
			end
			value, pos = deserialSwitch[case](buf, pos + 1)
			paired[valId] = value
			return value
		end

		if case ~= "nil" then
			value, pos = deserialSwitch[case](buf, pos)
		else
			-- TODO: Error here? Can it even get here?
			pos += 1
		end

		if value == nil then
			-- TODO: Error here
			return nil -- data corrupted
		end

		if pos - 2 > oldPos then
			existingCache(value)
		end
		return value
	end

	-- TODO: See if there are more spots to add errors
	@native
	function deserialTable(data: { [any]: any }): { [any]: any }
		local id = buffer.readu8(buf, pos)

		pos += 1

		local hasArray = id == ARRAY or id == TABLE

		if not hasArray and id ~= DICT then
			-- TODO: Error here
			return {} -- data corruption
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
						-- TODO: Error here
						return {}
					end
					data[index] = value
					continue
				end

				value = deserialCache(valId)
				if value == nil then
					-- TODO: Error here
					return {}
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
					-- TODO: Error here
					return {}
				end
				pos += 3
			end

			if not key then
				key = deserialCache(valId)
				if key == nil then
					-- TODO: Error here
					return {}
				end
			end

			valId = buffer.readu8(buf, pos)

			-- check if existing
			if valId == EQ_EXISTING then
				value = existing[buffer.readu16(buf, pos + 1)]
				if value == nil then
					-- TODO: Error here
					return {}
				end
				pos += 3
				data[key] = value
				continue
			end

			value = deserialCache(valId)
			if value == nil then
				-- TODO: Error here
				return {}
			end

			data[key] = value
		end
	end

	local data = deserialTable(returnedTab)

	table.clear(existing)

	return data, pos + 1
end

return table.freeze({
	serialize = tabSerializer,
	deserialize = tabDeserializer,
})
