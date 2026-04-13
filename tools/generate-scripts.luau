--[[
	Creates a directory with the given structure.
	- results
	 - /BufferSerializer
	 - .luaurc
	  - /vN -- version
	   - .luaurc
	   - serialize.luau
	   - deserialize.luau
       - /size
        - /... -- 1 script per size_dataset

	To run:
	cd to/repo/path

	lune run tools/generate-scripts
]]

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")

function cli_assert(cond: any, message: string): ()
	if not cond then
		print(message)
		process.exit(0)
	end
end

function printHelp(): ()
	print([[
Usage: lune run tools/generate-scripts

Creates a directory with the given structure.
	- results
	 - /BufferSerializer
	 - .luaurc
	  - /vN -- version
	   - .luaurc
	   - serialize.luau
	   - deserialize.luau
       - /size
        - /... -- 1 script per size_dataset

Available options:
  -h, --help: Display this usage message
	]])
end

if not fs.isDir("results") or not fs.isDir("results/BufferSerializer") then
	fs.writeDir("results/BufferSerializer")
end

if not fs.isFile("results/.luaurc") then
	local config = {
		aliases = {
			resources = "../resources",
		},
	}
	fs.writeFile("results/.luaurc", serde.encode("json", config, true))
end

cli_assert(fs.isDir("resources"), "resources directory must exist")

cli_assert(
	fs.isDir("resources/size_datasets"),
	"resources/size_datasets directory must exist"
)
cli_assert(
	fs.isDir("resources/size_datasets"),
	"resources/size_datasets directory must exist"
)
cli_assert(
	fs.isDir("resources/BufferSerializer"),
	"resources/BufferSerializer directory must exist when generating version scripts"
)

for _, input: string in process.args do
	if input == "-h" or input == "--help" then
		printHelp()
		process.exit(0)
	end
	print(`{input} is not a valid command, see help:`)
	printHelp()
	process.exit(0)
end

function get_serialize(): string
	return [[-- serialize
local Bench = require("@resources/luau-bench")
local format = require("@BufferSerializer")
local fs = require("@lune/fs")
local serde = require("@lune/serde")

local rawdata = {}
do
	local file_name = "resources/pokedex.json"
	assert(fs.isFile(file_name), `{file_name} does not exist`)
	local success, file_data = pcall(serde.decode, "json", fs.readFile(file_name))
	assert(success, `{file_name} could not be parsed`)
	rawdata = file_data
end

local benchData = Bench(format.serialize, rawdata):updateOutput(function(output)
	if type(output) == "string" then
		return string.len(output)
	elseif type(output) == "buffer" then
		return buffer.len(output)
	end
	return
end)

return {
	time = benchData.Speed.Data,
	space = benchData.Memory.Data,
	metadata = {
		size = benchData.Output,
	},
}
]]
end

function get_deserialize(): string
	return [[-- deserialize
local Bench = require("@resources/luau-bench")
local format = require("@BufferSerializer")
local fs = require("@lune/fs")
local serde = require("@lune/serde")

local rawdata = {}
do
	local file_name = "resources/pokedex.json"
	assert(fs.isFile(file_name), `{file_name} does not exist`)
	local success, file_data = pcall(serde.decode, "json", fs.readFile(file_name))
	assert(success, `{file_name} could not be parsed`)
	rawdata = file_data
end

local benchData = Bench(
	format.deserialize,
	format.serialize(rawdata)
):updateOutput()

return {
	time = benchData.Speed.Data,
	space = benchData.Memory.Data,
	metadata = {},
}
]]
end

-- [[ GENERATE SIZE ]]

for _, path: string in fs.readDir("resources/size_datasets") do
	cli_assert(
		fs.isDir(
			`resources/size_datasets/{path}`,
			`resources/size_datasets/{path} must be a directory`
		)
	)
	cli_assert(
		fs.isFile(`resources/size_datasets/{path}/TAXONOMY`),
		`resources/size_datasets/{path}/TAXONOMY must exist`
	)
	local contents: string = string.format(
		[[-- size
local format = require("@BufferSerializer")
local fs = require("@lune/fs")
local serde = require("@lune/serde")

local rawdata = serde.decode("json", fs.readFile("resources/size_datasets/%s/document.json"))
local data = format.serialize(rawdata)

return {
	time = {},
	space = {},
	metadata = {
		taxonomy = "%s",
		size = buffer.len(data),
		compression = {
			gzip = #serde.compress("gzip", data, 9),
			lz4 = #serde.compress("lz4", data, 9),
		},
	}
}
	]],
		path,
		fs.readFile(`resources/size_datasets/{path}/TAXONOMY`):sub(1, -2)
	)

	if not fs.isDir(`results/BufferSerializer/size}`) then
		fs.writeDir(`results/BufferSerializer/size`)
	end
	fs.writeFile(`results/BufferSerializer/size/{path}.luau`, contents)
end

local function gen_version(version: string)
	cli_assert(
		fs.isDir(`resources/BufferSerializer/{version}`),
		`resources/BufferSerializer/{version} must be a directory`
	)

	if not fs.isDir(`results/BufferSerializer/{version}`) then
		fs.writeDir(`results/BufferSerializer/{version}`)
	end

	local path: string = `../../../resources/BufferSerializer/{version}`

	fs.writeFile(
		`results/BufferSerializer/{version}/serialize.luau`,
		get_serialize()
	)
	fs.writeFile(
		`results/BufferSerializer/{version}/deserialize.luau`,
		get_deserialize()
	)

	local size_from: string = "results/BufferSerializer/size"
	local size_to: string = `results/BufferSerializer/{version}/size`

	fs.copy(size_from, size_to, true)

	local contents = {
		aliases = {
			BufferSerializer = path,
		},
	}

	fs.writeFile(
		`results/BufferSerializer/{version}/.luaurc`,
		serde.encode("json", contents, true)
	)
end

for _, version: string in fs.readDir("resources/BufferSerializer") do
	gen_version(version)
end

fs.removeDir(`results/BufferSerializer/size`)

return {}
