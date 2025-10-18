--[[
	Build:
 	lune build tools/parallel.luau -o parallel

 	Run:
 	lune run tools/parallel
 	 OR
 	./parallel
]]
local parallel = {}

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local serde = require("@lune/serde")
local stdio = require("@lune/stdio")
local task = require("@lune/task")

local proxyrequire = luau.load(fs.readFile("tools/proxyrequire.luau"), {
	debugName = "proxyrequire",
	environment = {
		require = function(path: string)
			return if path == "@lune/fs"
				then fs
				else error(`No such file or directory \`{path}\``)
		end,
		HOME = process.env.HOME,
		jsonDecode = function(msg: string)
			return serde.decode("json", msg)
		end,
	},
})()

print(proxyrequire("@Bench"))

local cache = {}
local SHARED_ENV = {
	require = nil,
	print = nil,
	getfenv = nil,
	setfenv = nil,
	loadstring = nil,
}

function cacheRequire(name: string)
	local fileData = fs.readFile(name)
	luau.load(fileData, {
		debugName = "@" .. name,
		environment = SHARED_ENV,
	})
end

return parallel
