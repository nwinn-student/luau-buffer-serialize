--!strict
--!optimize 2

local environments = {}

-- tossed together since it doesn't really matter
local function stringify(value: any)
	local typeValue = type(value)
	
	local strValue = tostring(value)
	
	if typeValue == "string" then
		return `"{value}"`
	end
	
	if typeValue ~= "buffer" and typeValue ~= "table" then
		return strValue
	end
	
	if typeValue == "buffer" then
		return `"{buffer.tostring(value)}"`
	end
	
	-- must be table...
	local s = "{ "
    for k, v in value do
        s ..= `[{stringify(k)}] = {stringify(v)},`
    end
    return s .. "} "
end

local test = {
	complete = function(name: string)
		print(`[TEST] {name} {
				if environments[debug.info(2, "s")] == false then
						"FAILED"
					else
						"PASSED"
			}`)
	end,
	run = function(cond: boolean, msg: string)
		if cond then
			return
		end
		print(`[TEST] FAILED: {msg} {debug.traceback("", 2)}`)
		environments[debug.info(2, "s")] = false
	end,
	newBuffer = function(...: number)
		local args = {...}
		local buf = buffer.create(#args)
		for i,v in args do
			buffer.writeu8(buf, i - 1, v)
		end
		return buf
	end,
	sizedBuffer = function(size: number, ...: number)
		local args = {...}
		local buf = buffer.create(size)
		for i,v in args do
			buffer.writeu8(buf, i - 1, v)
		end
		return buf
	end,
	serial = function(ori: buffer, new: buffer)
		local testFail = false
		
		local oriSize = buffer.len(ori)
		local newSize = buffer.len(new)
		
		if oriSize ~= newSize then
			print(`[TEST] FAILED: Expected size {
					oriSize
				} (got {
					newSize
				})`)
			environments[debug.info(2, "s")] = false
			testFail = true
		end
		for i=0, math.min(oriSize, newSize) - 1 do
			local oriByte = buffer.readu8(ori, i)
			local newByte = buffer.readu8(new, i)
			if oriByte ~= newByte then
				print(`[TEST] FAILED: Expected {
						oriByte
					} at position {i} (got {
						newByte
					})`)
				environments[debug.info(2, "s")] = false
				testFail = true
			end
		end
		
		if testFail then
			print(debug.traceback("", 2):sub(2 ,-1))
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
		
		print(`[TEST] FAILED: Expected {strOri} (got {strNew}) {
				debug.traceback("", 2)
			}`)
		environments[debug.info(2, "s")] = false
	end,
	newSerializer = function(v: any)
		
		type Serializer = (any, buffer, number, number)->(buffer, number, number)
		
		local typeV = type(v)
		
		local serializer = (if typeV == "nil" then
				require("../src/nil").serialize
			elseif typeV == "boolean" then
				require("../src/boolean").serialize
			elseif typeV == "buffer" then
				require("../src/buffer").serialize
			elseif typeV == "string" then
				require("../src/string").serialize
			elseif typeV == "number" then
				require("../src/number").serialize
			elseif typeV == "vector" then
				require("../src/vector").serialize
			elseif typeV == "table" then
				require("../src/table").serialize
			else
				require("../src/userdata").serialize) :: Serializer
		
		return function(v: any)
			return serializer(v, nil :: any, 0, 0)
		end
	end,
	newDeserializer = function(v: any)
		
		type Deserializer = (buffer, number)->(any, number)
		
		local typeV = type(v)
		
		local deserializer = (if typeV == "nil" then
				require("../src/nil").deserialize
			elseif typeV == "boolean" then
				require("../src/boolean").deserialize
			elseif typeV == "buffer" then
				require("../src/buffer").deserialize
			elseif typeV == "string" then
				require("../src/string").deserialize
			elseif typeV == "number" then
				require("../src/number").deserialize
			elseif typeV == "vector" then
				require("../src/vector").deserialize
			elseif typeV == "table" then
				require("../src/table").deserialize
			else
				require("../src/userdata").deserialize) :: Deserializer
		
		return function(v: any)
			return deserializer(v, 0)
		end
	end
}

return test
