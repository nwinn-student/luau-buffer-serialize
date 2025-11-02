local generateresources = {}

--[[
	NOT DONE!
	Adds files to the fs if not already present.

	Ensures:
	resources
		data
			benchdata.luau
			food-facts.luau
			pokedex.luau
			prize.luau
		luau-bench
			init.luau
			Print.luau
			Compare.luau
			Stats.luau
			Variant.luau
	Where luau-bench is downloaded from the git repo and the data folder is created from JSON libs

	To run:
	cd to/repo/path
	lune run tools/generateresources.luau
]]

local fs = require("@lune/fs")
local net = require("@lune/net")
--net.request(config)

if not fs.isDir("resources") then
	fs.writeDir("resources/data")
	fs.writeDir("resources/luau-bench")
end
print(fs.isFile("bench/compare.luau"))

-- Add msgpack
-- Add luau-bench
-- Add data

return generateresources
