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
		if buffer.len(ori) ~= buffer.len(new) then
			print(`[TEST] FAILED: Expected {
					buffer.len(ori)
				} (got {
					buffer.len(new)
				}) {
					debug.traceback("", 2)
				}`)
			environments[debug.info(2, "s")] = false
			return false
		end
		for i=0, buffer.len(ori) - 1 do
			local oriByte = buffer.readu8(ori, i)
			local newByte = buffer.readu8(new, i)
			if oriByte ~= newByte then
				print(`[TEST] FAILED: Expected {
						oriByte
					} at position {i} (got {
						newByte
					}) {
						debug.traceback("", 2)
					}`)
				environments[debug.info(2, "s")] = false
				return false
			end
		end
		return true
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
		
		print(`Expected {strOri} (got {strNew}) {
				debug.traceback("", 2)
			}`)
		environments[debug.info(2, "s")] = false
	end
}

return test
