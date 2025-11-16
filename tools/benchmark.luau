local benchmark = {}

local fs = require("@lune/fs")
local path = require("./path")
local process = require("@lune/process")
local serde = require("@lune/serde")
local summarize = require("./summarize")

local args = process.args

local options = {
	path = "",
}

function printHelp()
	print(string.format(
		[[
Usage: %s <path>

Available options:
  -h, --help: Display this usage message
  --skip=<str>:
  --view[=mode]:
  --output=<file>:
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
	if input:sub(1, 7) == "--view=" or input == "--view" then
		local view = input == "--view" and "Median" or input:sub(8)
		-- TODO: Add validity checks
		options.view = view
		continue
	end
	options.path = input
end

local relfile = path.relativeTo(debug.info(1, "s"))

local function processPath(file: string, data, fn)
	if not fs.isDir(file) and not fs.isFile(file) then
		return
	end

	-- TODO: skip if name matches skip stuff!

	if
		path.name(file) == "init"
		and (
			path.getextension(file) == "luau"
			or path.getextension(file) == "lua"
		)
	then
		-- no clue how to interpret this so.. it isn't supported
		return
	end

	if
		fs.isFile(file)
		and (
			path.getextension(file) == "luau"
			or path.getextension(file) == "lua"
		)
	then
		data[path.name(file)] = fn(relfile .. path.removeextension(file))
		return
	end

	data[path.name(file)] = data[path.name(file)] or {}
	for _, fi in fs.readDir(file) do
		processPath(file .. "/" .. fi, data[path.name(file)], fn)
	end
end

local data = if options.output and fs.isFile(options.output)
	then serde.decode("json", fs.readFile(options.output))
	else {}

local count = 0
processPath(options.path, {}, function(a0: string)
	count += 1
end)

processPath(options.path, data, function(a0: string)
	local data = require(a0)

	-- process data, we assume it matches
	-- if it doesn't this will just error
	local formattedData = {
		speed = {
			low = data.Speed.Low,
			median = data.Speed.Median,
			high = data.Speed.High,
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
			low = data.Memory.Low,
			median = data.Memory.Median,
			high = data.Memory.High,
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
	fs.writeFile(options.output, serde.encode("json", data))
end

-- TODO: Print data if necessary (--view)

return benchmark
