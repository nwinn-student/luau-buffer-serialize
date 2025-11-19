local summarize = {}

local Quartile_1 = 0.25
local Quartile_3 = 0.75

local function iqr(data: { number })
	local len = #data

	return data[(Quartile_3 * len) // 1] - data[(Quartile_1 * len) // 1]
end

local function stdev(data: { number }, avg: number)
	local variance = 0
	local count = #data

	for _, val in data do
		variance += (val - avg) ^ 2
	end
	return math.sqrt(variance / (count - 1))
end

summarize.iqr = iqr
summarize.stdev = stdev

return table.freeze(summarize)
