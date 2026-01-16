local path = {}

local fs = require("@lune/fs")
local process = require("@lune/process")

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

path.name = pathName
path.getextension = getExtension
path.removeextension = removeExtension
path.relativeTo = lazyrelative

return table.freeze(path)
