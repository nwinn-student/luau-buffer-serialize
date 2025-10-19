local parallelbench = {}

--[[
	Used to speed up benchmark times and still get good results

	To run:
	cd to/repo/path
	lune run tools/parallelbench.luau --codegen

	To build:
	lune build tools/parallelbench.luau -o parallelbench

	To run exe:
	./parallelbench --codegen
	OR equivalent
]]

local process = require("@lune/process")
local args = process.args
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local stdio = require("@lune/stdio")
local task = require("@lune/task")

local options = {
	skip = {} :: { string },
	parallel = true,
	percore = false,
	-- FIXME: unsure about linux/darwin
	cores = tonumber(process.env["NUMBER_OF_PROCESSORS"]) - 1,
	dir = "temp",
	verbose = false,
	options = "",
	output = {},
}

function printHelp()
	print(string.format(
		[[
Usage: %s [options]

luau must be findable via `$ luau`
When --dir is omitted, all luau files from the ./temp directory are run.

Available options:
  -h, --help: Display this usage message
  --dir=<n>: executes all scripts within the directory
  -np, --no-run-parallel: runs the benchmarks sequentially
  --skip=<n[,m]>: Skips executing scripts that start with the provided characters.
    | Uses lua pattern matching
  -vr, --verbose-results: Displays the expanded results of the benchmark
  -ppc, --process-per-core: If parallel, runs one process per core, assuming all are idle
  --remove-columns=<option,[option...]>: If non-verbose, removes option columns from the output
    | option: Speed | Memory | Output | Total

Unsupported options:
  -o=<n>,--output=<n>: outputs the results from the benchmarks into file n in Markdown
  --gen-hist: generates a histogram for the CLI

Supported luau options:
  --coverage: collect code coverage while running the code and output results to coverage.out
  -O<n>:compile with optimization level n (default 1, n should be between 0 and 2).
  -g<n>: compile with debug level n (default 1, n should be between 0 and 2).
  --profile: profile the code using 10000 Hz sampling and output results to profile.out
  --timetrace: record compiler time tracing information into trace.json
  --codegen: execute code using native code generation
]],
		process.env._
	))
end

for _, input in args do
	if input == "-h" or input == "--help" then
		printHelp()
		process.exit(0)
	end
	if input:sub(1, 5) == "--dir=" then
		options.dir = input:sub(7)
		continue
	end
	if input:sub(1, 7) == "--skip=" then
		options.skip = input:sub(8):split(",")
		continue
	end
	if input:sub(1, 17) == "--remove-columns=" then
		options.output = input:sub(18):split(",")
		continue
	end
	if input:sub(1, 4) == "--o=" or input:sub(1, 9) == "--output=" then
		print("Outputing the results to a .md file has yet to be implemented.")
	end
	if input == "--gen-hist" then
		print("Generating histograms has yet to be implemented.")
	end
	if input == "-np" or input == "--no-run-parallel" then
		options.parallel = false
		continue
	end
	if input == "-ppc" or input == "--process-per-core" then
		options.percore = true
		continue
	end
	if input == "-vr" or input == "--verbose-results" then
		options.verbose = true
		continue
	end
	if
		input == "--coverage"
		or input == "--timetrace"
		or input == "--codegen"
		or input == "--profile"
		or input == "-O0"
		or input == "-O1"
		or input == "-O2"
		or input == "g0"
		or input == "g1"
		or input == "g2"
	then
		if options.options == "" then
			options.options = input
			continue
		end
		options.options ..= " " .. input
		continue
	end

	print(`{input} is not a valid command, see help:`)
	printHelp()
	process.exit(0)
end

-- Both generatebenchscripts and generatesources MUST be run prior.

local files = fs.readDir(options.dir)
local encodedOptions = "'" .. serde.encode("json", options) .. "'"
-- FIXME: could be shell dependent... :<
encodedOptions = encodedOptions:gsub('"', '\\"')

function processCreate(fileName: string)
	return process.create("luau", {
		options.options,
		`{options.dir}/{fileName}`,
		"-a",
		fileName:sub(fileName:find("ser-") + 4, -6), -- leaves just the file name
		encodedOptions,
	}, { cwd = process.cwd, shell = true, stdio = "inherit" })
end

type Log = { [string]: { Serial: { string }, Deserial: { string } } }

local Log: Log = {
	BufferSerializer = { Serial = {}, Deserial = {} },
	MessagePack = { Serial = {}, Deserial = {} },
	unknown = { Serial = {}, Deserial = {} },
}
local tasks = {}

function getScheme(name: string): "BufferSerializer" | "unknown" | "MessagePack"
	return if name:sub(1, 2) == "bs"
		then "BufferSerializer"
		elseif name:sub(1, 2) == "mp" then "MessagePack"
		else "unknown"
end
function getAction(name: string): "Serial" | "Deserial"
	return if name:sub(4, 4) == "s" then "Serial" else "Deserial"
end

function spawner(fileName: string)
	local proc = processCreate(fileName)

	-- if generated scripts error, uncomment below
	--print(proc.stderr:read())
	--print(proc.stdout:read())
	if proc:status().ok then
		table.insert(
			Log[getScheme(fileName)][getAction(fileName)],
			string.sub(proc.stdout:readToEnd(), 1, -3)
		)
	end
	proc:kill()
	tasks[#tasks] = nil
end

function processFile(path: string)
	if path:sub(-5) ~= ".luau" then
		return
	end
	for _, bypass: string in options.skip do
		if path:match(`^{bypass}`) then
			return
		end
	end
	table.insert(tasks, 0)
	print(`Running file: {path}`)

	-- Maybe make it run processor - 1 at a time?
	if options.parallel then
		task.spawn(spawner, path)

		if options.percore then
			while #tasks == options.cores do
				task.wait()
			end
		end
	else
		spawner(path)
	end
end

local start = os.clock()
for _, path in files do
	processFile(path)
end

repeat
	task.wait()
until #tasks == 0

stdio.write(stdio.color("green"))

-- Find separation point?
for scheme, actions in Log do
	if #actions.Deserial == 0 and #actions.Serial == 0 then
		continue
	end
	print("Scheme: ", scheme)
	if #actions.Serial > 0 then
		print("Serial:")
		table.sort(actions.Serial)
		local msg = if options.verbose
			then table.concat(actions.Serial, "\n")
			else "\t" .. table.concat(actions.Serial, "\n\t")
		print(msg)
	end
	if #actions.Deserial > 0 then
		print("Deserial:")
		table.sort(actions.Deserial)
		local msg = if options.verbose
			then table.concat(actions.Deserial, "\n")
			else "\t" .. table.concat(actions.Deserial, "\n\t")
		print(msg)
	end
end

stdio.write(stdio.color("reset"))
print(`Took {os.clock() - start} seconds..`)

if not process.env._ then
	-- exe was manually clicked
	stdio.prompt("confirm", "Are you done?")
end

return parallelbench
