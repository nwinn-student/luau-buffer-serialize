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

function summarize(self: Bench.BenchData, name: string)
	self.Name = name
	benchStdev(self)

	local memStr = `{benchPrecision(self.Memory.Average, 3)} ± {benchPrecision(
		self.Memory.stdev,
		1
	)}`
	local outStr = `{self.Output}`
	local totalStr = `{benchPrecision(self.Speed.Total, 2)}`

	print(
		`{name}{string.rep(" ", 10 - #name)} | {benchPrecision(
			self.Speed.Average,
			4
		)} ± {benchPrecision(self.Speed.stdev, 2)} s | {memStr}{string.rep(
			" ",
			13 - #memStr
		)} kB | {if self.Output
			then `{outStr}{string.rep(" ", 7 - #outStr)} bytes | `
			else ""}({totalStr}{string.rep(" ", 5 - #totalStr)} s)`
	)
	return self
end

return summarize
