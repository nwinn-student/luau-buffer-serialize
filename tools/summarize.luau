-- Adds a function to luau-bench
local Bench = require("@Bench")
local benchPrecision = require("@Bench/Print").precision

-- Not tailored for speed
function stdev(arr: { number }, avg: number)
	local variance = 0
	local count = #arr

	for _, val: number in arr do
		variance += (val - avg) ^ 2
	end
	return math.sqrt(variance / (count - 1))
end

function benchStdev(self: Bench.BenchData)
	local mem = self.Memory
	local speed = self.Speed
	mem.stdev = stdev(mem.Data, mem.Average)
	speed.stdev = stdev(speed.Data, speed.Average)

	return self
end

local Quartile_1 = 0.25
local Quartile_3 = 0.75

-- interquartile range
function benchIQR(self: Bench.BenchData)
	local mem = self.Memory
	local speed = self.Speed

	local memLen = #mem.Data
	mem.IQR = mem.Data[(Quartile_3 * memLen) // 1]
		- mem.Data[(Quartile_1 * memLen) // 1]

	local spdLen = #speed.Data
	speed.IQR = speed.Data[(Quartile_3 * spdLen) // 1]
		- speed.Data[(Quartile_1 * spdLen) // 1]
end

function summarize(self: Bench.BenchData, arg: any)
	self.Name = arg.path
	benchStdev(self)
	benchIQR(self)

	--TODO: Have an option to specify avg +- stdev OR median +- iqr
	local nameStr = self.Name
	if #nameStr >= 10 then
		nameStr = nameStr:sub(1, 6 - #nameStr) .. ".."
	end
	nameStr ..= string.rep(" ", 10 - #nameStr)

	local isAvg = arg.options.avg

	local spd1 = if isAvg then self.Speed.Average else self.Speed.Median
	local spd2 = if isAvg then self.Speed.stdev else self.Speed.IQR

	local mem1 = if isAvg then self.Memory.Average else self.Memory.Median
	local mem2 = if isAvg then self.Memory.stdev else self.Memory.IQR

	local spdStr = `{benchPrecision(spd1, 4)} ± {benchPrecision(spd2, 2)}`
	local memStr = `{benchPrecision(mem1, 3)} ± {benchPrecision(mem2, 1)}`
	memStr ..= string.rep(" ", 13 - #memStr)
	local outStr = `{self.Output}`
	outStr ..= string.rep(" ", 7 - #outStr)
	local totalStr = `{benchPrecision(self.Speed.Total, 2)}`
	totalStr ..= string.rep(" ", 5 - #totalStr)

	local isSpeed = table.find(arg.options.output, "Speed")
	local isMemory = table.find(arg.options.output, "Memory")
	local isOutput = table.find(arg.options.output, "Output")
	local isTotal = table.find(arg.options.output, "Total")

	local format = nameStr
	if not isSpeed then
		format ..= ` | {spdStr} s`
	end
	if not isMemory then
		format ..= ` | {memStr} kB`
	end
	if not isOutput and self.Output then
		format ..= ` | {outStr} bytes`
	end
	if not isTotal then
		format ..= ` | ({totalStr} s)`
	end

	print(format)
	return self
end

return summarize
