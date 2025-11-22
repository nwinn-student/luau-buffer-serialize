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
	-- FIXME: unsure about linux/darwin
	cores = tonumber(process.env["NUMBER_OF_PROCESSORS"]) - 1,
	fps = 5,
	dir = "temp",
	verbose = false,
	avg = false,
	progress = false,
	options = "",
	output = {},
}

-- TODO: Add sorting options for non-verbose results
-- TODO: Apply sorting/filtering options for verbose too. Adding more options for row-wise filtering
function printHelp()
	print(string.format(
		[[
Usage: %s [options]

luau must be findable via `$ luau`
When --dir is omitted, all luau files from the ./temp directory are run.

Available options:
  -h, --help: Display this usage message
  --dir<=n>: executes all luau scripts within the directory
  --cores<=number>: The maximum amount of usable cores (1 = serial, inf = parallel)
  --skip<=n[,m]>: Skips executing scripts that start with the provided characters.
    | Uses lua pattern matching
  -vr, --verbose-results: Displays the expanded results of the benchmark
  --remove-columns<=option,[option...]>: If non-verbose, removes option columns from the output
    | option: Speed | Memory | Output | Total
  -a, --avg: Displays avg +- stdev instead of the default median +- iqr
  -p, --progress: Displays a progress bar and duration when running
  --fps<=number>: The frequency to update the progress bar

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
	if input:sub(1, 6) == "--dir=" then
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
	if input:sub(1, 8) == "--cores=" then
		local cores = tonumber(input:sub(9))
		-- Fractional cores might exist later (cuz it sounds cool)
		assert(
			cores and cores > 0,
			`--cores<=number> must take a number between 1 and inf, got {input:sub(
				9
			)}`
		)
		options.cores = cores
		continue
	end
	if input:sub(1, 8) == "--fps=" then
		local fps = tonumber(input:sub(9))
		-- Fractional cores might exist later (cuz it sounds cool)
		assert(
			fps and fps > 0,
			`--fps<=number> must take a number between 1 and inf, got {input:sub(
				9
			)}`
		)
		options.fps = fps
		continue
	end
	if input == "--gen-hist" then
		print("Generating histograms has yet to be implemented.")
	end
	if input == "-vr" or input == "--verbose-results" then
		options.verbose = true
		continue
	end
	if input == "-a" or input == "--avg" then
		options.avg = true
		continue
	end
	if input == "-p" or input == "--progress" then
		options.progress = true
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
		or input == "-g0"
		or input == "-g1"
		or input == "-g2"
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

local tempFiles = fs.readDir(options.dir)
local files = {}
for i, path in tempFiles do
	if path:sub(-5) ~= ".luau" then
		continue
	end
	local doContinue = false
	for _, bypass: string in options.skip do
		if path:match(`^{bypass}`) then
			doContinue = true
			break
		end
	end
	if doContinue then
		continue
	end
	table.insert(files, path)
end

local encodedOptions = "'" .. serde.encode("json", options) .. "'"
-- FIXME: could be shell dependent... :<
encodedOptions = encodedOptions:gsub('"', '\\"')
--print(encodedOptions)

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

local currentDisplayPath = ""

function triggerRunning(path: string)
	currentDisplayPath = "[  Running  ] " .. path
end
function triggerCompleted(path: string)
	currentDisplayPath = "[ Completed ] " .. path
end

local tasks = {
	running = 0,
	completed = 0,
	count = 0,
}
function tasks:run(path: string)
	tasks.running += 1
	tasks.count += 1
	triggerRunning(path)
end
function tasks:complete(path: string)
	tasks.completed += 1
	tasks.count -= 1
	triggerCompleted(path)
end

if options.progress then
	task.spawn(function()
		local startTime = os.clock()
		local startTasks = #files
		stdio.write("\n\n")
		repeat
			task.wait(1 / options.fps)
			stdio.write("\r\b\r\b\r") -- resets to start
			stdio.write(
				currentDisplayPath .. (" "):rep(43 - #currentDisplayPath) .. "\n"
			)
			local progress = (">"):rep(
				((tasks.running * 0.5 + tasks.completed) / (1.5 * startTasks))
					* 34
					// 1
			)
			progress ..= (" "):rep(34 - #progress)
			local duration = (100 * (os.clock() - startTime) // 1) / 100
			stdio.write(`{progress} | {duration} s\n`)
		until tasks.completed == startTasks
		stdio.write("\r\b\r\b\r") -- resets to start
		-- fill old w/ spaces
		stdio.write((" "):rep(45) .. "\n" .. (" "):rep(45) .. "\n")
		stdio.write("\r\b\r\b\r") -- resets to start
		currentDisplayPath = ""
	end)
end

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
	tasks:complete(fileName)
end

function processFile(path: string)
	tasks:run(path)

	task.spawn(spawner, path)

	while tasks.count == options.cores do
		task.wait()
	end
end

local start = os.clock()
for _, path in files do
	processFile(path)
end

repeat
	task.wait()
until options.progress and tasks.count == 0 and currentDisplayPath == ""
	or not options.progress and tasks.count == 0

stdio.write(stdio.color("green"))

-- Find separation point?
for scheme, actions in Log do
	if #actions.Deserial == 0 and #actions.Serial == 0 then
		continue
	end
	print("Scheme: ", scheme, (" "):rep(15))
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
