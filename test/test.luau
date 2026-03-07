--!strict
--!optimize 2

--[[
	Test API

	newBuffer(...: number | string): buffer
	sizedBuffer(size: number, ...: number | string): buffer
	run(cond: boolean, message: string)
	-- We can use type system to do precursor check
	compare<T>(expected: T, obtained: T): boolean
	-- Deprecated and to be removed
	serial<T>(expected: T, obtained: T): boolean

	-- Maybe later
	expectedComparable(expected: any): Comparable
		:compareObtained(obtained: any): boolean
	-- Maybe later for batch
	expectBatch<T>(...: T...): ExpectBatch<T...>
		:obtainedBatch(...: T...): boolean

]]

local test = {}

local function getSize(tab: { number | string })
	local size = 0
	for _, value in tab do
		if type(value) == "string" then
			size += #value
			continue
		end
		assert(type(value) == "number")
		size += 1
	end
	return size
end

function test.run(cond: boolean, message: string)
	if cond then
		return
	end
	print(`{message} {debug.traceback("", 2)}`)
end

function test.sizedBuffer(size: number, ...: number | string)
	local args = { ... }
	local buf = buffer.create(size)
	local pos = 0
	for _, value in args do
		if type(value) == "string" then
			buffer.writestring(buf, pos, value)
			pos += #value
			continue
		end
		assert(type(value) == "number")
		buffer.writeu8(buf, pos, value)
		pos += 1
	end
	return buf
end

function test.newBuffer(...: number | string)
	local size = getSize({ ... })
	return test.sizedBuffer(size, ...)
end

local function tosimplestring(value: any)
	local typeValue = type(value)
	return if typeValue == "string"
		then `"{value}"`
		elseif typeValue == "buffer" then `b"{buffer.tostring(value)}"`
		else tostring(value)
end

local function stringCompare(expected: string, obtained: string)
	local hasFailed = false
	local traceback = debug.traceback("", 3)

	local expectedSize = #expected
	local obtaintedSize = #obtained

	if expectedSize ~= obtaintedSize then
		print(`Expected size {expectedSize} (got {obtaintedSize})`)
		hasFailed = true
	end

	-- Q: if the character isn't print-able what do we do?
	-- A: Chose to print byte as well.
	-- Q: What if it is a batch of characters?
	-- A: Vertical reading exists.
	-- We don't account for unicode, would be silly
	-- this is VERY slow, we could match?
	for i = 0, math.min(expectedSize, obtaintedSize) - 1 do
		local expectedChar = expected:sub(i, i)
		local expectedByte = expectedChar:byte()
		local obtainedChar = obtained:sub(i, i)
		local obtainedByte = obtainedChar:byte()

		if expectedByte ~= obtainedByte then
			print(
				`Expected {expectedChar} ({expectedByte}) at position {i} (got {obtainedChar} ({obtainedByte}))`
			)
			hasFailed = true
		end
	end

	if hasFailed then
		print(traceback:sub(2, -1))
	end
	return hasFailed
end

local function tableCompare(expected: { [any]: any }, obtained: { [any]: any })
	local cyclicStorage = { [expected] = true }
	local hasFailed = false
	local traceback = debug.traceback("", 3)

	local function comparer(expected: { [any]: any }, obtained: { [any]: any })
		local keyStorage = {}

		for key, value in expected do
			keyStorage[key] = true

			local obtainedValueAtKey = obtained[key]
			if obtainedValueAtKey == nil then
				print(
					`Expected [{tosimplestring(key)}] = {tosimplestring(value)} (got nil)`
				)
				hasFailed = true
				continue
			end

			if cyclicStorage[value] then
				if cyclicStorage[obtainedValueAtKey] ~= value then
					print(
						`Expected [{tosimplestring(key)}] = *CYCLIC* (got {tosimplestring(
							value
						)})`
					)
					hasFailed = true
				end
				continue
			end

			-- When making tests, do NOT have tables as keys, we don't have a
			--  correct way to determine which table key is linked with which.
			if type(key) == "table" then
				continue
			end
			if type(value) == "table" and type(obtainedValueAtKey) == "table" then
				cyclicStorage[value] = true
				cyclicStorage[obtainedValueAtKey] = value
				comparer(value, obtainedValueAtKey)
				continue
			end

			if not test.compare(value, obtainedValueAtKey) then
				hasFailed = true
			end
		end

		for key, value in obtained do
			if not keyStorage[key] then
				print(
					`Expected [{tosimplestring(key)}] = nil (got {tosimplestring(
						value
					)})`
				)
				hasFailed = true
			end
		end
	end

	comparer(expected, obtained)

	if hasFailed then
		print(traceback:sub(2, -1))
	end
	return hasFailed
end

function test.compare<T>(expected: T, obtained: T)
	if
		expected == obtained
		or tosimplestring(expected) == tosimplestring(obtained)
	then
		return true
	end

	local traceback = debug.traceback("", 2)

	local expectedType = type(expected)
	local obtainedType = type(obtained)
	if expectedType ~= obtainedType then
		print(`Expected type {expectedType} (got {obtainedType}) {traceback}`)
		return false
	end

	if expectedType == "string" then
		-- match obtained against expected?
		return stringCompare(expected, obtained)
	elseif expectedType == "buffer" then
		return stringCompare(buffer.tostring(expected), buffer.tostring(obtained))
	elseif expectedType == "table" then
		return tableCompare(expected, obtained)
	else
		print(`Expected {expected} (got {obtained}) {traceback}`)
		return false
	end
end

-- Deprecated for removal: Use `test.compare`
test.serial = test.compare

return test
