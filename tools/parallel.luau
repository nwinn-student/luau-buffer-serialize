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

local cache = {}
local SHARED_ENV
SHARED_ENV = table.freeze({
	require = function(name: string)
		print(process.cwd)
		-- how do i get which script is calling?
		local fileData = proxyrequire(name)
		luau.load(fileData, {
			debugName = "@" .. name,
			environment = SHARED_ENV,
		})()

		return nil
	end,
	--print = nil,
	getfenv = nil,
	setfenv = nil,
	loadstring = nil,
})

SHARED_ENV.require("tools/sample")

return parallel
