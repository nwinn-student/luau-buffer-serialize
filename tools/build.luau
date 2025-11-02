local build = {}

--[[
	Used to build the src for Releases

	To run:
	cd to/repo/path
	lune run tools/build.luau --name=BufferSerializer
]]

local process = require("@lune/process")
local args = process.args
local _stdio = require("@lune/stdio")
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")

local function pathName(path: string)
	path = path:gsub("\\", "/")
	local pathSplit = string.split(path, "/")
	if fs.isDir(path) then
		if pathSplit[#pathSplit] == "" then
			return pathSplit[#pathSplit - 1]
		end
		return pathSplit[#pathSplit]
	end
	return pathSplit[#pathSplit]:sub(1, -6)
end

local options = {
	body = "src",
	name = pathName(process.cwd),
}

function printHelp()
	print(string.format(
		[[
Usage: %s [options]

Available options:
  -h, --help: Display this usage message
  --name=<str>: The name of the root ModuleScript and output file, default is directory name
  --body=<dir>: The directory containing the tree of ModuleScripts, default is src
	]],
		process.env._
	))
end

for _, input in args do
	if input == "-h" or input == "--help" then
		printHelp()
		process.exit(0)
	end
	if input:sub(1, 7) == "--name=" then
		options.name = input:sub(8)
		continue
	end
	if input:sub(1, 7) == "--body=" then
		options.body = input:sub(8)
		continue
	end
	print(`{input} is not a valid command, see help:`)
	printHelp()
	process.exit(0)
end

local root = roblox.Instance.new("ModuleScript")
root.Name = options.name
root.Source = fs.readFile(options.body .. "/init.luau")

local function addScripts(path: string, par: any)
	if path:find("/init.luau") then
		return
	end
	if fs.isDir(path) then
		if not fs.isFile(path .. "/init.luau") then
			return
		end
		local branch = roblox.Instance.new("ModuleScript")
		branch.Name = pathName(path)
		branch.Parent = par
		branch.Source = fs.readFile(path .. "/init.luau")
		for _, file in fs.readDir(path) do
			if not fs.isDir(path .. "/" .. file) and file:sub(-5) ~= ".luau" then
				continue
			end
			addScripts(path .. "/" .. file, branch)
		end
		return
	end
	local script = roblox.Instance.new("ModuleScript")
	script.Name = pathName(path)
	script.Parent = par
	script.Source = fs.readFile(path)
end

for _, path in fs.readDir(options.body) do
	if not fs.isDir(options.body .. "/" .. path) and path:sub(-5) ~= ".luau" then
		continue
	end
	addScripts(options.body .. "/" .. path, root)
end

fs.writeFile(options.name .. ".rbxm", roblox.serializeModel({ root }))

return build
