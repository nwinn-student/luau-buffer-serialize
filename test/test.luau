--!strict
--!optimize 2

local meta = {
	add = function(self, val)
		table.insert(self, val)
		return self
	end,
}
meta.__index = meta

-- tossed together since it doesn't really matter
-- how do we handle cyclic? and how do we identify different cyclics?
local function stringify(value: any, parTree: any?)
	local typeValue = type(value)

	local strValue = tostring(value)

	if typeValue == "string" then
		return `"{value}"`
	end

	if typeValue ~= "buffer" and typeValue ~= "table" then
		return strValue
	end

	if typeValue == "buffer" then
		return `buffer"{buffer.tostring(value)}"`
	end

	parTree = parTree or setmetatable({}, meta)
	for i, v in parTree do
		if v == value then
			return `*CYCLIC#{i}*`
		end
	end

	parTree:add(value)
	-- must be table...
	local s = "{ "
	for k, v in value do
		s ..= `[{stringify(k, parTree)}] = {stringify(v, parTree)},`
	end
	return s .. "} "
end

local test = {
	run = function(cond: boolean, msg: string)
		if cond then
			return
		end
		print(`{msg} {debug.traceback("", 2)}`)
	end,
	newBuffer = function(...: number)
		local args = { ... }
		local buf = buffer.create(#args)
		for i, v in args do
			buffer.writeu8(buf, i - 1, v)
		end
		return buf
	end,
	sizedBuffer = function(size: number, ...: number)
		local args = { ... }
		local buf = buffer.create(size)
		for i, v in args do
			buffer.writeu8(buf, i - 1, v)
		end
		return buf
	end,
	serial = function(ori: buffer, new: buffer)
		local testFail = false

		local oriSize = buffer.len(ori)
		local newSize = buffer.len(new)

		if oriSize ~= newSize then
			print(`Expected size {oriSize} (got {newSize})`)
			testFail = true
		end
		for i = 0, math.min(oriSize, newSize) - 1 do
			local oriByte = buffer.readu8(ori, i)
			local newByte = buffer.readu8(new, i)
			if oriByte ~= newByte then
				print(`Expected {oriByte} at position {i} (got {newByte})`)
				testFail = true
			end
		end

		if testFail then
			print(debug.traceback("", 2):sub(2, -1))
		end
	end,
	compare = function(ori: any, new: any)
		if ori == new then
			return
		end

		local strOri = stringify(ori)
		local strNew = stringify(new)

		if strOri == strNew then
			return
		end

		print(`Expected {strOri} (got {strNew}) {debug.traceback("", 2)}`)
	end,
}

return test
