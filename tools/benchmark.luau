local benchmark = {}

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")

local args = process.args

local options = {
	path = "",
}

function printHelp()
	print(string.format(
		[[
Usage: %s <path>

Available options:
  -h, --help: Display this usage message
  --skip=<str>:
  --view[=mode]:
  --output=<file>:
	]],
		process.env._
	))
end

for _, input in args do
	if input == "-h" or input == "--help" then
		printHelp()
		process.exit(0)
	end
	if input:sub(1, 7) == "--skip=" then
		options.skip = input:sub(8):split(",")
		continue
	end
	if input:sub(1, 9) == "--output=" then
		options.output = input:sub(10)
		continue
	end
	if input:sub(1, 7) == "--view=" or input == "--view" then
		local view = input == "--view" and "Median" or input:sub(8)
		-- TODO: Add validity checks
		options.view = view
		continue
	end
	options.path = input
end

local function getExtension(path: string)
	local ext = path:split(".")
	if #ext == 1 then
		return ""
	end
	if #ext == 2 and ext[1] == "" then
		return ""
	end
	return ext[#ext]
end

local function removeExtension(path: string)
	local ext = path:split(".")
	-- ...
	if #ext == 1 then
		return ext[1]
	end
	if #ext == 2 and ext[1] == "" then
		return path
	end
	return table.concat(ext, ".", 1, #ext - 1)
end
local function pathName(path: string)
	path = path:gsub("\\", "/")
	local pathSplit = string.split(path, "/")
	if fs.isDir(path) then
		if pathSplit[#pathSplit] == "" then
			return pathSplit[#pathSplit - 1]
		end
		return pathSplit[#pathSplit]
	end
	return removeExtension(pathSplit[#pathSplit])
end

local function lazyrelative(path: string)
	local cwd = process.cwd:gsub("\\", "/")
	path = path:gsub("\\", "/")
	path = path:sub(1, -1 - #pathName(path))

	local paths = path:split("/")
	local cwdpaths = cwd:split("/")
	local relativepath = ""

	for _, dir in paths do
		if dir:find("^%a:") or dir == "" then
			continue
		end
		relativepath ..= "../"
	end

	for _, dir in cwdpaths do
		if dir:find("^%a:") or dir == "" then
			continue
		end
		relativepath ..= dir .. "/"
	end

	return relativepath
end

local relfile = lazyrelative(debug.info(1, "s"))

local function processPath(path: string, data, fn)
	if not fs.isDir(path) and not fs.isFile(path) then
		return
	end

	if
		pathName(path) == "init"
		and (getExtension(path) == "luau" or getExtension(path) == "lua")
	then
		-- no clue how to interpret this so.. it isn't supported
		return
	end

	if
		fs.isFile(path)
		and (getExtension(path) == "luau" or getExtension(path) == "lua")
	then
		data[pathName(path)] = fn(relfile .. removeExtension(path))
		return
	end

	data[pathName(path)] = {}
	for _, file in fs.readDir(path) do
		processPath(path .. "/" .. file, data[pathName(path)], fn)
	end
end

local data = if options.output and fs.isFile(options.output)
	then serde.decode("json", fs.readFile(options.output))
	else {}

local count = 0
processPath(options.path, {}, function(a0: string)
	count += 1
end)

processPath(options.path, data, require)

if options.output then
	fs.writeFile(options.output, serde.encode("json", data))
end

-- TODO: Print data if necessary (--view)

return benchmark
