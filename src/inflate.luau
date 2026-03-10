--!optimize 2
--!strict

local function inflateInternal(data: buffer, minSize: number, oldSize: number)
	if oldSize == 0 then
		return buffer.create(minSize), minSize
	end

	while minSize > oldSize do
		oldSize *= 2
	end

	local temp = buffer.create(oldSize)
	buffer.copy(temp, 0, data)
	return temp, oldSize
end

--[[
	Inflates the buffer size to be at least the new position.
	@ Uses a doubling approach to inflate.
]]
local function inflate(data: buffer, minSize: number, oldSize: number)
	if minSize > oldSize then
		-- Allows for multiple return inlining
		local newData, newSize = inflateInternal(data, minSize, oldSize)
		return newData, newSize
	end
	return data, oldSize
end

return inflate
