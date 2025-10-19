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

function summarize(self: Bench.BenchData, arg: any)
	self.Name = arg.path
	benchStdev(self)

	local nameStr = self.Name
	if #nameStr >= 10 then
		nameStr = nameStr:sub(1, 6 - #nameStr) .. ".."
	end
	nameStr ..= string.rep(" ", 10 - #nameStr)
	local spdStr = `{benchPrecision(self.Speed.Average, 4)} ± {benchPrecision(
		self.Speed.stdev,
		2
	)}`
	local memStr = `{benchPrecision(self.Memory.Average, 3)} ± {benchPrecision(
		self.Memory.stdev,
		1
	)}`
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
