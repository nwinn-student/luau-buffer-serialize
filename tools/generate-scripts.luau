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

if not fs.isFile("results/.luaurc") then
	local config = {
		aliases = {
			resources = "../resources",
		},
	}
	fs.writeFile("results/.luaurc", serde.encode("json", config, true))
end

assert(
	fs.isDir("resources") and fs.isDir("resources/datasets"),
	"resources/datasets directory must exist"
)

--[[
	Do we make two generators or have one?
	Two may be easier to understand??


]]
local version: string

for _, arg in process.args do
	-- .... same as usual...?
end

-- [[ GENERATE SERIALIZE ]]
--

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
local fs = require("@lune/fs")
local format = require("@BufferSerializer")
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
--

for _, path in fs.readDir("resources/datasets") do
	local contents = string.format(
		[[-- deserialize
local Bench = require("@resources/luau-bench")
local fs = require("@lune/fs")
local format = require("@BufferSerializer")
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

--TODO: Add version support
if process.args[1] ~= "" then
	-- copy the above scripts, but also re-assign @BufferSerializer to another path in a localized .luaurc
	-- we would need a tool to download versions then
	-- idk... i feel like this tool should not need the internet at all
	-- fetch-resources could do downloading versions tho
	local path = `../../resources/BufferSerializer{version}`

	local from = "results/BufferSerializer"
	local to = `results/BufferSerializer/v{version}`
	fs.copy(from, to, true)

	local contents = {
		aliases = {
			-- assume it is in resources with the name BufferSerializerVERSION
			-- release creates a rbxm with the same name
			BufferSerializer = path,
		},
	}
	fs.writeFile(
		`results/BufferSerializer/v{version}/.luaurc`,
		serde.encode("json", contents, true)
	)
end

return {}
