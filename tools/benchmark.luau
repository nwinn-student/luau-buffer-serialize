local benchmark = {}

local fs = require("@lune/fs")
local path = require("./utils/path")
local process = require("@lune/process")
local progress = require("./utils/progress")
local serde = require("@lune/serde")
local summarize = require("./utils/summarize")

local args = process.args

local options = {
	path = "",
	skip = {} :: { string },
	output = "benchmark-results.json", -- or bench/results.json, unsure which yet
}

function printHelp()
	print(string.format(
		[[
Usage: %s <path>

Codegen is enabled by default, to disable set path environment
 LUNE_LUAU_JIT to "0" or "false" or "off"

Available options:
  -h, --help: Display this usage message
  --skip=<path[,path]>: Excludes the given paths that match from running
  --output=<file>: Which file to store the results in
    Defaults to benchmark-results.json
	]],
		process.env._
	))
end

for _, input in args do
	if input == "-h" or input == "--help" then
		printHelp()
		process.exit(0)
	end
	if input:sub(1, 7) == "--skip=" then
		options.skip = input:sub(8):split(",")
		continue
	end
	if input:sub(1, 9) == "--output=" then
		options.output = input:sub(10)
		continue
	end
	options.path = input
end

local source = debug.info(1, "s")
local prefile = options.path:sub(
	1,
	-1 - #path.name(options.path) - #path.getextension(options.path)
)
local relfile = path.relativeTo(source) .. prefile

local function processPath(file: string, data, fn)
	if not fs.isDir(prefile .. file) and not fs.isFile(prefile .. file) then
		return
	end

	for _, v in options.skip do
		if file:sub(1, #v) == v then
			return
		end
	end

	local fileName = path.name(file)
	local fileExt = path.getextension(file)

	if fileName == "init" and (fileExt == "luau" or fileExt == "lua") then
		-- no clue how to interpret this so.. it isn't supported
		return
	end

	if fs.isFile(prefile .. file) and (fileExt == "luau" or fileExt == "lua") then
		data[fileName] = fn(relfile .. path.removeextension(file))
		return
	end

	data[fileName] = data[fileName] or {}
	for _, fi in fs.readDir(prefile .. file) do
		processPath(file .. "/" .. fi, data[fileName], fn)
	end
end

local data = if fs.isFile(options.output)
	then serde.decode("json", fs.readFile(options.output))
	else {}

local count = 0
processPath(options.path:sub(#prefile + 1), {}, function(_: string)
	count += 1
end)
local progressCounter = progress.new(count)

processPath(options.path:sub(#prefile + 1), data, function(file: string)
	progressCounter:run(file:sub(1 + #relfile))
	local data = require(file)
	progressCounter:complete(file:sub(1 + #relfile))

	-- data is assumed to be of the type BenchData defined in luau-bench
	local formattedData = {
		speed = {
			median = data.Speed.Median,
			iqr = summarize.iqr(data.Speed.Data),

			min = data.Speed.Minimum,
			average = data.Speed.Average,
			max = data.Speed.Maximum,
			stdev = summarize.stdev(data.Speed.Data, data.Speed.Average),

			hist = {
				data.Speed.Histogram[1],
				data.Speed.Histogram[2],
				data.Speed.Histogram[3],
				data.Speed.Histogram[4],
				data.Speed.Histogram[5],
				data.Speed.Histogram[6],
				data.Speed.Histogram[7],
				data.Speed.Histogram[8],

				min = data.Speed.Low,
				max = data.Speed.High,
				range = data.Speed.Histogram.Range,
			},
		},
		memory = {
			median = data.Memory.Median,
			iqr = summarize.iqr(data.Memory.Data),

			min = data.Memory.Minimum,
			average = data.Memory.Average,
			max = data.Memory.Maximum,
			stdev = summarize.stdev(data.Memory.Data, data.Memory.Average),

			hist = {
				data.Memory.Histogram[1],
				data.Memory.Histogram[2],
				data.Memory.Histogram[3],
				data.Memory.Histogram[4],
				data.Memory.Histogram[5],
				data.Memory.Histogram[6],
				data.Memory.Histogram[7],
				data.Memory.Histogram[8],

				min = data.Memory.Low,
				max = data.Memory.High,
				range = data.Memory.Histogram.Range,
			},
		},
		output = data.Output,
	}

	return formattedData
end)

if options.output then
	fs.writeFile(options.output, serde.encode("json", data, true))
end

return benchmark
