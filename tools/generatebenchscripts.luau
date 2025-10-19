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
	task.spawn(function()
		fs.writeFile(
			`temp/bs-ser-{path}`,
			[[
				-- Generated file...
				local args = {}

				local json = require("@json")

				do
					local temp: {string} = {...}

					args.path = temp[1]
					args.options = json.decode(table.concat(temp, " ", 2))
				end

				local Bench = require("@Bench")
				local BufferSerializer = require("@BufferSerializer")
				local summarize = require("@summarize")

				local results = Bench(
					BufferSerializer.serialize,
					json.decode(require("@data/" .. args.path))
				):updateOutput(buffer.len)

				if args.verbose then
					results:withName(args.path):print()
				else
					summarize(results, args)
				end
			]]
		)
		fs.writeFile(
			`temp/bs-deser-{path}`,
			[[
				-- Generated file...
				local args = {}

				local json = require("@json")

				do
					local temp: {string} = {...}

					args.path = temp[1]
					args.options = json.decode(table.concat(temp, " ", 2))
				end

				local Bench = require("@Bench")
				local BufferSerializer = require("@BufferSerializer")
				local summarize = require("@summarize")

				local results = Bench(
					BufferSerializer.deserialize,
					BufferSerializer.serialize(json.decode(require("@data/" .. args.path)))
				):updateOutput()

				if args.verbose then
					results:withName(args.path):print()
				else
					summarize(results, args)
				end
			]]
		)
		fs.writeFile(
			`temp/mp-ser-{path}`,
			[[
				-- Generated file...
				local args = {}

				local json = require("@json")

				do
					local temp: {string} = {...}

					args.path = temp[1]
					args.options = json.decode(table.concat(temp, " ", 2))
				end

				local Bench = require("@Bench")
				local msgpack = require("@msgpack")
				local summarize = require("@summarize")

				local results = Bench(
					msgpack.encode,
					json.decode(require("@data/" .. args.path))
				):updateOutput(string.len)

				if args.verbose then
					results:withName(args.path):print()
				else
					summarize(results, args)
				end
			]]
		)
		fs.writeFile(
			`temp/mp-deser-{path}`,
			[[
				-- Generated file...
				local args = {}

				local json = require("@json")

				do
					local temp: {string} = {...}

					args.path = temp[1]
					args.options = json.decode(table.concat(temp, " ", 2))
				end

				local Bench = require("@Bench")
				local msgpack = require("@msgpack")
				local summarize = require("@summarize")

				local results = Bench(
					msgpack.decode,
					msgpack.encode(json.decode(require("@data/" .. args.path)))
				):updateOutput()

				if args.verbose then
					results:withName(args.path):print()
				else
					summarize(results, args)
				end
			]]
		)
	end)
end

return generatebenchscripts
