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
local stdio = require("@lune/stdio")
local task = require("@lune/task")

local skip: { string } = {}
local isParallel = true
local directory = "temp"
local options = ""
local isVerbose = false

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
  --skip=<n[,m]>: Skips executing scripts that start with the provided characters
  -vr, --verbose-results: Displays the expanded results of the benchmark

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
		directory = input:sub(7)
		continue
	end
	if input:sub(1, 7) == "--skip=" then
		skip = input:sub(8):split(",")
		continue
	end
	if input:sub(1, 4) == "--o=" or input:sub(1, 9) == "--output=" then
		print("Outputing the results to a .md file has yet to be implemented.")
	end
	if input == "--gen-hist" then
		print("Generating histograms has yet to be implemented.")
	end
	if input == "-np" or input == "--no-run-parallel" then
		isParallel = false
		continue
	end
	if input == "-vr" or input == "--verbose-results" then
		isVerbose = true
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
		options ..= input .. " "
		continue
	end

	print(`{input} is not a valid command, see help:`)
	printHelp()
	process.exit(0)
end

-- Both generatebenchscripts and generatesources MUST be run prior.

local files = fs.readDir(directory)

function processCreate(fileName: string)
	return process.create("luau", {
		options,
		`{directory}/{fileName}`,
		"-a",
		tostring(isVerbose),
		fileName:sub(1, -6), -- remoes .luau
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
	local startMemory = gcinfo()
	local proc = processCreate(fileName)

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
	for _, bypass: string in skip do
		if path:match(`^{bypass}`) then
			return
		end
	end
	table.insert(tasks, 0)
	print(`Running file: {path}`)

	if isParallel then
		task.spawn(spawner, path)
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
		local msg = if isVerbose
			then table.concat(actions.Serial, "\n")
			else "\t" .. table.concat(actions.Serial, "\n\t")
		print(msg)
	end
	if #actions.Deserial > 0 then
		print("Deserial:")
		table.sort(actions.Deserial)
		local msg = if isVerbose
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
