--[[
	Creates a directory in results/ with the given name.

	<takes version (path is assumed????)? since we want to be able to gen stuff for versions>
	- is: results
	 - /BufferSerializer
	  - /serialize
	   - /...
	  - /deserialize
	   - /...
	  - /vN
	   - /serialize
	   - /deserialize

	- compare looks at the provided paths and looks for serialize / deserialize!
	 - it does not care if there are others inside

	To run:
	cd to/repo/path

	lune run tools/generate-scripts
]]

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")

if not fs.isDir("results") or not fs.isDir("results/BufferSerializer") then
	fs.writeDir("results/BufferSerializer")
end
if not fs.isDir("results/BufferSerializer/serialize") then
	fs.writeDir("results/BufferSerializer/serialize")
end
if not fs.isDir("results/BufferSerializer/deserialize") then
	fs.writeDir("results/BufferSerializer/deserialize")
end
if not fs.isDir("results/BufferSerializer/size") then
	fs.writeDir("results/BufferSerializer/size")
end

if not fs.isFile("results/.luaurc") then
	local config = {
		aliases = {
			resources = "../resources",
		},
	}
	fs.writeFile("results/.luaurc", serde.encode("json", config, true))
end

assert(fs.isDir("resources"), "resources directory must exist")

assert(fs.isDir("resources/datasets"), "resources/datasets directory must exist")

local options = {
	versions = {},
}

function printHelp()
	print(string.format(
		[[
Usage: %s [options]

Available options:
  -h, --help: Display this usage message
  --verisons=<tag[,tag]>: Generates time/space benchmark scripts for the provided versions
      ALL can be used to generate all downloaded versions.
	]],
		process.env._
	))
end

for _, input in process.args do
	if input == "-h" or input == "--help" then
		printHelp()
		process.exit(0)
	end
	if input:sub(1, 11) == "--versions=" then
		options.versions = input:sub(12):split(",")
		continue
	end
	print(`{input} is not a valid command, see help:`)
	printHelp()
	process.exit(0)
end

-- [[ GENERATE SERIALIZE ]]

for _, path in fs.readDir("resources/datasets") do
	assert(
		fs.isDir(
			`resources/datasets/{path}`,
			`resources/datasets/{path} must be a directory`
		)
	)
	assert(
		fs.isFile(`resources/datasets/{path}/TAXONOMY`),
		`resources/datasets/{path}/TAXONOMY must exist`
	)

	local contents = string.format(
		[[-- serialize
local Bench = require("@resources/luau-bench")
local format = require("@BufferSerializer")
local fs = require("@lune/fs")
local serde = require("@lune/serde")

local benchData = Bench(
	format.serialize,
	serde.decode("json", fs.readFile("resources/datasets/%s/document.json"))
):updateOutput(function(output)
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
		output_size = benchData.Output,
		taxonomy = "%s"
	}
}
	]],
		path,
		fs.readFile(`resources/datasets/{path}/TAXONOMY`):sub(1, -2)
	)

	fs.writeFile(`results/BufferSerializer/serialize/{path}.luau`, contents)
end

-- [[ GENERATE DESERIALIZE ]]

for _, path in fs.readDir("resources/datasets") do
	local contents = string.format(
		[[-- deserialize
local Bench = require("@resources/luau-bench")
local format = require("@BufferSerializer")
local fs = require("@lune/fs")
local serde = require("@lune/serde")

local benchData = Bench(
	format.deserialize,
	format.serialize(
		serde.decode("json", fs.readFile("resources/datasets/%s/document.json"))
	)
):updateOutput()

return {
	time = benchData.Speed.Data,
	space = benchData.Memory.Data,
	metadata = { taxonomy = "%s" }
}
	]],
		path,
		fs.readFile(`resources/datasets/{path}/TAXONOMY`):sub(1, -2)
	)

	fs.writeFile(`results/BufferSerializer/deserialize/{path}.luau`, contents)
end

-- [[ GENERATE SIZE ]]

for _, path in fs.readDir("resources/datasets") do
	local contents = string.format(
		[[-- size
local format = require("@BufferSerializer")
local fs = require("@lune/fs")
local serde = require("@lune/serde")

local rawdata = serde.decode("json", fs.readFile("resources/datasets/%s/document.json"))
local data = format.serialize(rawdata)

function get_freq(data: any, par: { any })
	local data_type = type(data)

	if data_type ~= "table" then
		return { [data] = 1 }
	end

	if par[data] then
		return {}
	end
	par[data] = true

	local freq = {}

	for key, value in data do
		local key_freq = get_freq(key, par)
		local value_freq = get_freq(value, par)

		for i, v in key_freq do
			freq[i] = (freq[i] or 0) + v
		end
		for i, v in value_freq do
			freq[i] = (freq[i] or 0) + v
		end
	end

	return freq
end

function populate_pairs(data: any)
	local freq = get_freq(data, {})

	local words = {}
	for word, count in freq do
		table.insert(words, word)
	end

	table.sort(words, function(a0, a1): boolean
		return freq[a0] > freq[a1]
	end)

	local ids = {
		string = 0,
		number = 0,
	}

	for _, word in words do
		local count = freq[word]
		if count < 5 then
			continue
		end
		if word == 0 or word == 1 or word == "" then
			continue
		end
		if word == true or word == false then
			continue
		end
		-- we don't have nan or vectors or userdata
		-- since json doesn't support?

		ids[type(word)] += 1
		local new_id = ids[type(word)]

		-- we could limit id but our datasets are small enough

		format.pair(new_id, word)
	end
end
populate_pairs(rawdata)

local pair_data = format.serialize(rawdata)

do
	local string = require("@BufferSerializer/string")
	local number = require("@BufferSerializer/number")

	if string.resetWrite then
		string.resetWrite()
		string.resetRead()
		number.resetWrite()
		number.resetRead()
	else
		local link = require("@BufferSerializer/link")
		table.clear(link.values)
	end
end

return {
	time = { 0 },
	space = { 0 },
	metadata = {
		taxonomy = "%s",
		size = buffer.len(data),
		pair_size = buffer.len(pair_data),
		compression = {
			brotli = #serde.compress("brotli", data),
			gzip = #serde.compress("gzip", data),
			lz4 = #serde.compress("lz4", data),
			zlib = #serde.compress("zlib", data),
			zstd = #serde.compress("zstd", data),

			pair_brotli = #serde.compress("brotli", pair_data),
			pair_gzip = #serde.compress("gzip", pair_data),
			pair_lz4 = #serde.compress("lz4", pair_data),
			pair_zlib = #serde.compress("zlib", pair_data),
			pair_zstd = #serde.compress("zstd", pair_data),
		},
	}
}
	]],
		path,
		fs.readFile(`resources/datasets/{path}/TAXONOMY`):sub(1, -2)
	)

	fs.writeFile(`results/BufferSerializer/size/{path}.luau`, contents)
end

local function gen_version(version: string)
	assert(
		fs.isDir(`resources/BufferSerializer/{version}`),
		`resources/BufferSerializer/{version} must be a directory`
	)

	if not fs.isDir(`results/BufferSerializer/{version}`) then
		fs.writeDir(`results/BufferSerializer/{version}`)
	end

	local path = `../../../resources/BufferSerializer/{version}`

	local serial_from = "results/BufferSerializer/serialize"
	local serial_to = `results/BufferSerializer/{version}/serialize`
	local deserial_from = "results/BufferSerializer/deserialize"
	local deserial_to = `results/BufferSerializer/{version}/deserialize`
	local size_from = "results/BufferSerializer/size"
	local size_to = `results/BufferSerializer/{version}/size`

	fs.copy(serial_from, serial_to, true)
	fs.copy(deserial_from, deserial_to, true)
	fs.copy(size_from, size_to, true)

	local contents = {
		aliases = {
			-- assume it is in resources with the name BufferSerializerVERSION
			-- release creates a rbxm with the same name
			BufferSerializer = path,
		},
	}

	fs.writeFile(
		`results/BufferSerializer/{version}/.luaurc`,
		serde.encode("json", contents, true)
	)
end

for _, version in options.versions do
	if version == "ALL" then
		assert(
			fs.isDir("resources/BufferSerializer"),
			"resources/BufferSerializer directory must exist when generating version scripts"
		)

		for _, version in fs.readDir("resources/BufferSerializer") do
			gen_version(version)
		end

		break
	end

	gen_version(version)
end

return {}
