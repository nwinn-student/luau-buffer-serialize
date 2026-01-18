local benchmark = {}

--[[
	Used to run benchmarks

	1. Expects that tools/fetch-resources has been run (located in resources)
	2. Expects that tools/generate-scripts has been run (scripts located in results/<name>)

	For no-codegen:
		export LUNE_LUAU_JIT="false"

	To run:
	cd to/repo/path

	lune run tools/benchmark results
]]

local fs = require("@lune/fs")
local path = require("@self/path")
local process = require("@lune/process")
local progress = require("@self/progress")
local serde = require("@lune/serde")
local summarize = require("@self/summarize")

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

Examples:
Runs all .lua(u) files, recursively, under the 'results' directory
  lune run tools/benchmark results

Same as above, but does not run the files/directories starting with 'foo' or 'bar'
  lune run tools/benchmark results --skip=foo,bar
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
	assert(fs.isDir(input), `{input} does not exist in the file system`)
	options.path = input
end

assert(#options.path ~= 0, "path was not initialized")

local source = debug.info(1, "s")
local relfile = path.relativeTo(source) -- .. options.path

local function processPath(file: string, data, fn)
	if not fs.isDir(file) and not fs.isFile(file) then
		return
	end

	for _, v in options.skip do
		if file:sub(1, #v) == v or file:find("^" .. v) then
			return
		end
	end

	local fileName = path.name(file)
	local fileExt = path.getextension(file)

	if fileName == "init" and (fileExt == "luau" or fileExt == "lua") then
		-- no clue how to interpret this so.. it isn't supported
		return
	end

	if fs.isFile(file) and (fileExt == "luau" or fileExt == "lua") then
		local results = fn(relfile .. path.removeextension(file))

		if results then
			data[fileName] = results
		end

		return
	elseif fs.isFile(file) then
		return
	end

	data[fileName] = data[fileName] or {}
	for _, fi in fs.readDir(file) do
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
for _, name in fs.readDir(options.path) do
	processPath(`{options.path}/{name}`, {}, function(_: string)
		count += 1
	end)
end

local progressCounter = progress.new(count)

type BenchData = {
	time: { number },
	space: { number },
	metadata: { [string]: any }?,
}

-- The relative to root to source to path
-- Relative to root to source: (../../../usr/prog/bs/)
-- Source to path: (results/)
local pathsize = #relfile + #options.path + 1

local function processData(file: string)
	progressCounter:run(file:sub(1 + pathsize))

	-- table expected, ensures we can modify the values without errors
	local data: BenchData = table.clone(require(file))

	-- Validation of BenchData format
	assert(type(data) == "table", `table expected (got {type(data)})`)

	for key, value in data do
		assert(
			key == "metadata" or key == "time" or key == "space",
			`{key} is not supported`
		)
		assert(
			type(value) == "table",
			`table expected for '{key}' (got {type(data)})`
		)
	end

	for meta_key in data.metadata do
		assert(
			type(meta_key) == "string",
			`string expected for 'metadata' key (got {type(meta_key)})`
		)
	end

	-- performs validation and morphs table to fit desired shape
	data.time = summarize.format(data.time)
	data.space = summarize.format(data.space)

	progressCounter:complete(file:sub(1 + pathsize))

	return data
end

for _, name in fs.readDir(options.path) do
	processPath(`{options.path}/{name}`, data, processData)
end

if options.output then
	fs.writeFile(options.output, serde.encode("json", data, true))
end

return benchmark
