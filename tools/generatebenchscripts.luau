local generatebenchscripts = {}

--[[
	Run generateresources.luau first!

	To run:
	cd to/repo/path
	lune run tools/generatebenchscripts.luau
]]

local fs = require("@lune/fs")
local task = require("@lune/task")

local files = {}
if fs.isDir("resources/data") then
	for i, path in fs.readDir("resources/data") do
		if not fs.isDir(`resources/data/{path}`) then
			files[i] = path
		end
	end
end

fs.writeDir("temp")

for _, path in files do
	local luauPath = path:sub(1, -6) -- removes .luau
	task.spawn(function()
		fs.writeFile(
			`temp/bs-ser-{path}`,
			string.format(
				[[
				local Bench = require("@Bench")
				local BufferSerializer = require("@BufferSerializer")
				local summarize = require("@summarize")
				summarize(
					Bench(
						BufferSerializer.serialize,
						require("@json").decode(require("@data/%s"))
					):updateOutput(),
					"%s"
				)
			]],
				luauPath,
				luauPath
			)
		)
		fs.writeFile(
			`temp/bs-deser-{path}`,
			string.format(
				[[
				local Bench = require("@Bench")
				local BufferSerializer = require("@BufferSerializer")
				local summarize = require("@summarize")
				summarize(
					Bench(
						BufferSerializer.deserialize,
						BufferSerializer.serialize(require("@json").decode(require("@data/%s")))
					):updateOutput(),
					"%s"
				)
			]],
				luauPath,
				luauPath
			)
		)
		fs.writeFile(
			`temp/mp-deser-{path}`,
			string.format(
				[[
				local Bench = require("@Bench")
				local msgpack = require("@msgpack")
				local summarize = require("@summarize")
				summarize(
					Bench(
						msgpack.decode,
						msgpack.encode(require("@json").decode(require("@data/%s")))
					):updateOutput(),
					"%s"
				)
			]],
				luauPath,
				luauPath
			)
		)
	end)
end

return generatebenchscripts
