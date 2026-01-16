local benchmark = {}

--[[
	Used to run benchmarks

	1. Expects that tools/fetch-resources has been run (located in resources)
	2. Expects that tools/generate-scripts has been run (scripts located in results/<name>)

	For no-codegen:
		export LUNE_LUAU_JIT="false"

	To run:
	cd to/repo/path

	lune run tools/benchmark results/BufferSerializer
]]

local fs = require("@lune/fs")
local path = require("./utils/path")
local process = require("@lune/process")
local progress = require("./utils/progress")
local serde = require("@lune/serde")
local summarize = require("./utils/summarize")

local options = {
	path = "",
	skip = {} :: { string },
	output = "benchmark-results.json", -- or bench/results.json, unsure which yet
}

function printHelp()
	print(string.format(
		[[
Usage: %s <path>

Codegen is enabled by default, to disable set environment
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

for _, input in process.args do
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
		if file:sub(1, #v) == v or file:find("^" .. v) then
			return
		end
	end

	local fileName = path.name(prefile .. file)
	local fileExt = path.getextension(file)

	if fileName == "init" and (fileExt == "luau" or fileExt == "lua") then
		-- no clue how to interpret this so.. it isn't supported
		return
	end

	if fs.isFile(prefile .. file) and (fileExt == "luau" or fileExt == "lua") then
		local results = fn(relfile .. path.removeextension(file))

		if results then
			data[fileName] = results
		end

		return
	elseif fs.isFile(prefile .. file) then
		return
	end

	data[fileName] = data[fileName] or {}
	for _, fi in fs.readDir(prefile .. file) do
		processPath(file .. "/" .. fi, data[fileName], fn)
	end
end

local data = {}

if fs.isFile(options.output) then
	local success, output_data =
		pcall(serde.decode, "json", fs.readFile(options.output))
	assert(success, `{options.output} was not valid JSON`)
	if success then
		assert(
			type(output_data) == "table",
			`{options.output} did not contain a table`
		)
		data = output_data
	end
end

local count = 0
processPath(options.path:sub(#prefile + 1), {}, function(_: string)
	count += 1
end)
local progressCounter = progress.new(count)

type BenchData = {
	time: { number },
	space: { number },
	metadata: { [string]: any }?,
}

processPath(options.path:sub(#prefile + 1), data, function(file: string)
	progressCounter:run(file:sub(1 + #relfile))

	local data: BenchData = require(file)

	progressCounter:complete(file:sub(1 + #relfile))

	return {
		time = summarize.format(data.time),
		space = summarize.format(data.space),
		metadata = data.metadata,
	}
end)

if options.output then
	fs.writeFile(options.output, serde.encode("json", data, true))
end

return benchmark
