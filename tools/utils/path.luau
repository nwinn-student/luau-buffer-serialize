local path = {}

local fs = require("@lune/fs")
local process = require("@lune/process")

local function getExtension(path: string): string
	local ext: { string } = path:split(".")
	if #ext == 1 then
		return ""
	end
	if #ext == 2 and ext[1] == "" then
		return ""
	end
	return ext[#ext]
end

local function removeExtension(path: string): string
	local ext: { string } = path:split(".")
	-- ...
	if #ext == 1 then
		return ext[1]
	end
	if #ext == 2 and ext[1] == "" then
		return path
	end
	return table.concat(ext, ".", 1, #ext - 1)
end
local function pathName(path: string): string
	path = path:gsub("\\", "/")
	local pathSplit: { string } = string.split(path, "/")
	if fs.isDir(path) then
		if pathSplit[#pathSplit] == "" then
			return pathSplit[#pathSplit - 1]
		end
		return pathSplit[#pathSplit]
	end
	return removeExtension(pathSplit[#pathSplit])
end

local function lazyrelative(path: string): string
	local cwd: string = process.cwd:gsub("\\", "/")
	path = path:gsub("\\", "/")
	path = path:sub(1, -1 - #pathName(path))

	local paths: { string } = path:split("/")
	local cwdpaths: { string } = cwd:split("/")
	local relativepath: string = ""

	for _, dir: string in paths do
		if dir:find("^%a:") or dir == "" then
			continue
		end
		relativepath ..= "../"
	end

	for _, dir: string in cwdpaths do
		if dir:find("^%a:") or dir == "" then
			continue
		end
		relativepath ..= dir .. "/"
	end

	return relativepath
end

path.name = pathName
path.getextension = getExtension
path.removeextension = removeExtension
path.relativeTo = lazyrelative

return table.freeze(path)
