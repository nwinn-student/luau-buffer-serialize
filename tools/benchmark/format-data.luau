--[[
    Used to prepare data `{ number }` into the specific format
     used by the benchmark tool.
]]

export type Data = {
	sample_size: number, -- number of kept runs

	median: number,
	iqr: number, -- q3 - q1
	mad: number, -- median absolute deviation ( median(|x_i - median|) )
	mild_outliers: number, -- q1 - 1.5 * iqr and q3 + 1.5 * iqr

	min: number,
	average: number,
	max: number,
	stdev: number,

	-- of pattern: ^%(%d%.%d+e[+-]?%d+ to %d%.%d+e[+-]?%d+%)$
	-- ["(lower to upper)"] = count
	hist: { [string]: number },
}

local function avg(data: { number }): number
	local total: number = 0
	for _, cost: number in data do
		total += cost
	end
	return total / #data
end

local function stdev(data: { number }, average: number)
	local variance: number = 0
	local count: number = #data

	for _, cost: number in data do
		variance += (cost - average) ^ 2
	end
	return math.sqrt(variance / (count - 1))
end

local function percentile(data: { number }, percentage: number): number
	local index: number = ((percentage / 100) * #data) // 1
	return data[index ~= 0 and index or 1]
end

local function sformat(first: number, second: number): string
	return string.format("(%.3e to %.3e)", first, second)
end

-- how much do we take out?
local function hist(data: { number }, iqr: number): { [string]: number }
	local form: { [string]: number } = {}
	local box_amount: number = 8

	local histLow: number
	do
		local temp_histLow: number = percentile(data, 25) - 1.5 * iqr
		histLow = if temp_histLow < 0 then 0 else temp_histLow
	end
	local histHigh: number = percentile(data, 75) + 1.5 * iqr
	local histRange: number = (histHigh - histLow) / box_amount

	if histRange == 0 then
		form[sformat(0, 0)] = #data
		return
	end

	local cache: number = 0
	local cacheBox: number = 1
	local priorCost: number = -2 ^ 32
	local lowerBound: number = histLow
	local upperBound: number = histLow + histRange

	for _, cost: number in data do
		if cost == priorCost then
			cache += 1
			continue
		end

		if lowerBound <= cost and cost <= upperBound then
			cache += 1
			priorCost = cost
			continue
		end

		if cost < histLow or cost > histHigh then
			-- entered infrequently
			continue
		end

		local box: number = cacheBox
		repeat
			lowerBound += histRange
			upperBound += histRange
			box += 1
		until lowerBound <= cost and cost <= upperBound

		if cache > 0 then
			form[sformat(
				histLow + histRange * cacheBox,
				histLow + histRange * box
			)] =
				cache
		end

		cache = 1
		cacheBox = box

		priorCost = cost
	end

	if cacheBox == box_amount then
		form[sformat(
			histLow + histRange * (box_amount - 1),
			histLow + histRange * box_amount
		)] =
			cache
	end

	return form
end

local function mad(data: { number }, median: number): number
	local temp_data: { number } = {}

	for _, cost: number in data do
		table.insert(temp_data, math.abs(cost - median))
	end

	table.sort(temp_data)

	return percentile(temp_data, 50)
end

local function mild_outliers(data: { number }, iqr: number)
	local count: number = 0
	local lower: number = percentile(data, 25) - 1.5 * iqr
	local upper: number = percentile(data, 75) + 1.5 * iqr
	for _, cost: number in data do
		if cost < lower or cost > upper then
			count += 1
		end
	end
	return count
end

--[[
	Formats the given numerical data

	- Provides enough statistical information that
	 most other valuable measurements can be derived.

	@param data - an array of numbers
	@param options - allows for the box_amount for hist to be specified

	@return a formatted version of the data
]]
local function format_data(data: { number }): Data
	table.sort(data) -- we expect no negative numbers**

	local formatted: Data = {
		sample_size = #data,

		median = percentile(data, 50),
		iqr = percentile(data, 75) - percentile(data, 25),

		min = data[1],
		average = avg(data),
		max = data[#data],
	}
	formatted.mad = mad(data, formatted.median)
	formatted.mild_outliers = mild_outliers(data, formatted.iqr)
	formatted.stdev = stdev(data, formatted.average)
	formatted.hist = hist(data, formatted.iqr)

	return formatted
end

return format_data
