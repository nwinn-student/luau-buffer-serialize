local summarize = {}

function sum(t: { number })
	local total = 0
	for _, v in t do
		total += v
	end
	return total
end

local function precision(x: number, n: number)
	if x ~= x then
		return "nan"
	end
	if x == math.huge or x == -math.huge then
		return "inf"
	end
	-- removed support for negative values since we abs them prior at input
	if x < 1e-9 then
		return "0"
	end

	local exp = math.log10(x) // 1
	if exp >= 0 then
		-- ensure x is rounded to correct value
		local decimalRound = math.pow(10, exp + 1)
		return (math.round(x * decimalRound) / decimalRound) .. ""
	end
	local value = x / math.pow(10, exp)
	local strValue = tostring(value)
	local len = #strValue

	if len == n + 1 then
		return strValue .. "e" .. exp
	elseif len > n + 1 then
		return string.sub(strValue, 1, n + 1) .. "e" .. exp
	else
		-- len < n + 1
		local precZero = value % 1 == 0 and string.rep("0", n + 1 - len)
			or "." .. string.rep("0", n - len)
		return strValue .. precZero .. "e" .. exp
	end
end

local function stdev(data: { number }, avg: number)
	local variance = 0
	local count = #data

	for _, val in data do
		variance += (val - avg) ^ 2
	end
	return math.sqrt(variance / (count - 1))
end

function metrics(self: Format, data: { number })
	local len = #data

	self.min = data[1]
	self.max = data[len]

	self.median = data[(0.5 * len) // 1]

	local q3 = data[(0.75 * len) // 1]
	local q1 = data[(0.25 * len) // 1]

	self.iqr = if q3 and q1 then q3 - q1 else nil
end

function hist(self: Format, data: { number })
	local boxCount = 8

	local len = #data

	local lowIndex = (0.05 * len) // 1
	local histLow = data[lowIndex ~= 0 and lowIndex or 1]
	local histHigh = data[(0.95 * len) // 1]
	local histRange = if histHigh and histLow
		then (histHigh - histLow) / boxCount
		else 0

	if histRange == 0 then
		self.hist[`({precision(0, 4)} to {precision(0, 4)})`] = len
		self.average = sum(data) / len
		return
	end

	local total = 0
	local cache = 0
	local cacheBox = 1
	local priorV = -2 ^ 32
	local lowerBound = histLow
	local upperBound = histLow + histRange

	for _, v in data do
		total += v

		if v == priorV then
			cache += 1
			continue
		end

		if lowerBound <= v and v <= upperBound then
			cache += 1
			priorV = v
			continue
		end

		if v < histLow or v > histHigh then
			-- entered infrequently
			continue
		end

		local box = cacheBox
		repeat
			lowerBound += histRange
			upperBound += histRange
			box += 1
		until lowerBound <= v and v <= upperBound

		self.hist[`({precision(histLow + histRange * cacheBox, 4)} to {precision(
			histLow + histRange * box,
			4
		)})`] =
			cache

		cache = 1
		cacheBox = box

		priorV = v
	end

	if cacheBox == boxCount then
		self.hist[`({precision(histLow + histRange * (boxCount - 1), 4)} to {precision(
			histLow + histRange * boxCount,
			4
		)})`] =
			cache
	end

	self.average = total / len
	self.stdev = stdev(data, self.average)
end

type Format = {
	median: number,
	iqr: number,

	min: number,
	average: number,
	max: number,
	stdev: number,

	hist: { [string]: number },
}

function summarize.format(data: { number }): Format
	local format = { hist = {} }

	table.sort(data)

	-- All negative values will be removed
	local lastNegPos = 0
	for i, v in data do
		if v >= 0 then
			lastNegPos = i
			break
		end
	end

	if lastNegPos ~= 1 then
		local len = #data

		table.move(data, lastNegPos, len, 1, data)

		-- remove copies
		for i = len - lastNegPos, len do
			data[i] = nil
		end
	end

	metrics(format, data)
	hist(format, data)

	return format
end
summarize.precision = precision

return table.freeze(summarize)
