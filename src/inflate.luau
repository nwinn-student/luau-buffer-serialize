--!optimize 2
--!strict

--[[
	Inflates the buffer size to be at least the new position.
	@ Uses a doubling approach to inflate.
]]--
@native
local function inflate(data: buffer, minSize: number, oldSize: number)
	while minSize > oldSize do
		oldSize *= 2
	end

	local temp = buffer.create(oldSize)
	buffer.copy(temp, 0, data)
	return temp, oldSize
end

return inflate
