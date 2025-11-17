local benchmark = {}

local fs = require("@lune/fs")
local path = require("./utils/path")
local process = require("@lune/process")
local progress = require("./utils/progress")
local serde = require("@lune/serde")
local summarize = require("./summarize")
local task = require("@lune/task")

local args = process.args

local options = {
	path = "",
}

function printHelp()
	print(string.format(
		[[
Usage: %s <path>

Codegen is enabled by default, to disable set path environment
 LUNE_LUAU_JIT to "0" or "false" or "off"

Available options:
  -h, --help: Display this usage message
  --skip=<str[,str]>: Skips
  --view[=mode]: Displays the results
    Verbose | Median | Average, defaults to Median
  --output=<file>: Which file to store the results in
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
		if view ~= "Median" and view ~= "Average" and view ~= "Verbose" then
			print(`{input} is not a view, see help:`)
			printHelp()
			process.exit(1)
		end
		options.view = view
		continue
	end
	options.path = input
end

local source = debug.info(1, "s")
local relfile = path.relativeTo(source)

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
processPath(options.path, {}, function(_: string)
	count += 1
end)
local progressCounter = progress.new(count)

processPath(options.path, data, function(file: string)
	progressCounter:run(path.name(file))
	local data

	task.defer(function()
		data = require(file)
	end)

	repeat
		task.wait()
	until data

	progressCounter:complete(path.name(file))

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

task.wait(1 / 2.5)

if options.output then
	fs.writeFile(options.output, serde.encode("json", data))
end

-- TODO: Print data if necessary (--view)

return benchmark
