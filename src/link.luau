local inflate = require("./inflate")

local link = {}

-- string: 1 to 1343
-- number: 1 to 1055
-- vector: 1 to 1055
-- userdata: 1 to 1039

link.values = {}

@native
function link.serialize(value: number, buf: buffer, pos: number, size: number)
	if pos + 2 > size then
		buf, size = inflate(buf, pos + 2, size)
	end
	buffer.writeu16(buf, pos, value)
	return buf, pos + (value > 255 and 2 or 1), size, value :: any
end

return link
