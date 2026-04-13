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
type Data = format_data.Data
type PreBenchData = {
	time: { number },
	space: { number },
	metadata: { [string]: any }?,
}
type BenchData = {
	time: Format,
	space: Format,
	metadata: { [string]: any }?,
}
type Format = {
	[string]: (Data | Format)?,
}
type CommandOptions = {
	path: string,
	skip: { string },
	output: string,
}

local format_data: ({ number }) -> Data = require("@self/format-data")
local fs = require("@lune/fs")
local path = require("@self/path")
local process = require("@lune/process")
local progress = require("@self/progress")
local serde = require("@lune/serde")
local t = require("@self/t")

local source: string = debug.info(1, "s")
local relfile: string = path.relativeTo(source)
local options: CommandOptions = {
	path = "",
	skip = {},
	output = "benchmark-results.json",
}
local validatePreBenchData: (BenchData) -> (boolean, string) = t.strictInterface({
	time = t.array(t.number),
	space = t.array(t.number),
	metadata = t.optional(t.map(t.string, t.any)),
})

function cli_assert(cond: any, message: string)
	if not cond then
		print(message)
		print()
		printHelp()
		process.exit(0)
	end
end
function printHelp(): ()
	print([[
Usage: lune run tools/benchmark [options] <path>

Codegen is enabled by default, to disable set environment
 LUNE_LUAU_JIT to "0" or "false" or "off"
 - `export LUNE_LUAU_JIT="false"`

Argument:
  path: The location of the .lua(u) files to obtain benchmark results from
    All run files must return 
	  `{ time: { number }, space: { number }, metadata: { [string]: any }? }`

Available options:
  -h, --help: Display this usage message
  --skip=<path[,path]>: Excludes the given paths that match from running
  --output=<file>: Which file to store the results in
    Defaults to benchmark-results.json

Examples:
|- results
|-- foo.luau
|-- bar.luau
|-- baz.luau

Runs all .lua(u) files, recursively, under the 'results' directory
  lune run tools/benchmark results

Same as above, but does not run the files/directories starting with 'foo' or 'bar'
  lune run tools/benchmark results --skip=foo,bar
	]])
end

local function processPath(
	file: string,
	data: Format,
	fn: (file: string) -> BenchData?
): ()
	if not fs.isDir(file) and not fs.isFile(file) then
		return
	end

	for _, v: string in options.skip do
		if file:sub(1, #v) == v or file:find("^" .. v) then
			return
		end
	end

	local fileName: string = path.name(file)
	local fileExt: string = path.getextension(file)

	if fileName == "init" and (fileExt == "luau" or fileExt == "lua") then
		-- no clue how to interpret this so.. it isn't supported
		return
	end

	if fs.isFile(file) and (fileExt == "luau" or fileExt == "lua") then
		local results: BenchData? = fn(relfile .. path.removeextension(file))

		if results then
			data[fileName] = results
		end

		return
	elseif fs.isFile(file) then
		return
	end

	data[fileName] = data[fileName] or {}
	for _, fi: string in fs.readDir(file) do
		processPath(file .. "/" .. fi, data[fileName], fn)
	end
end

for _, input: string in process.args do
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
	cli_assert(fs.isDir(input), `{input} does not exist in the file system`)
	options.path = input
end

cli_assert(#options.path ~= 0, "path was not initialized")

local data: Format = {}

if fs.isFile(options.output) then
	local success: boolean, output_data =
		pcall(serde.decode, "json", fs.readFile(options.output))
	cli_assert(success, `{options.output} was not valid JSON`)
	cli_assert(
		type(output_data) == "table",
		`{options.output} did not contain a table`
	)
	data = output_data
end

local count: number = 0
for _, name: string in fs.readDir(options.path) do
	processPath(`{options.path}/{name}`, {}, function(_: string)
		count += 1
	end)
end

local progressCounter: progress.Progress = progress.new(count)

-- The relative to root to source to path
-- Relative to root to source: (../../../usr/prog/bs/)
-- Source to path: (results/)
local pathsize: number = #relfile + #options.path + 1

local function processData(file: string): BenchData
	local fileName: string = file:sub(1 + pathsize)
	progressCounter:run(fileName)

	local data: PreBenchData = require(file)
	cli_assert(validatePreBenchData(data))
	local formatted_data: BenchData = {
		time = format_data(data.time),
		space = format_data(data.space),
		metadata = data.metadata,
	}

	progressCounter:complete(fileName)

	return formatted_data
end

for _, name: string in fs.readDir(options.path) do
	processPath(`{options.path}/{name}`, data, processData)
end

if options.output then
	fs.writeFile(options.output, serde.encode("json", data, true))
end

return benchmark
