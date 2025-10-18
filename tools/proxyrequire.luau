--!nocheck
--!nolint
local fs = require("@lune/fs")

-- Simple alias finding
local function getAlias(filePath: string)
	if filePath:sub(1, 1) ~= "@" then
		return false
	end
	if not fs.isFile(".luaurc") then
		return false
	end
	local alias = filePath:sub(2, filePath:find("/") or 0 - 1)

	-- Inefficient approach
	local contents = jsonDecode(fs.readFile(".luaurc"))

	local actualPath = if contents and contents.aliases
		then contents.aliases[alias]
		else nil
	if not actualPath then
		return false
	end

	-- If the end of the path is "/", remove it
	if actualPath:sub(-1) == "/" then
		actualPath = actualPath:sub(1, -2)
	end

	-- If the start is ~ it is HOME
	-- sometimes there are implentations, not always
	if actualPath:sub(1, 1) == "~" then
		actualPath = HOME .. actualPath:sub(2)
	end

	return filePath:gsub("@" .. alias, actualPath)
end

-- from: https://github.com/lune-org/docs/blob/main/modules/sandbox.luau
local function discoverAndReadScript(filePath: string): string
	filePath = getAlias(filePath) or filePath

	local scriptContents: string

	if fs.isFile(filePath) then
		scriptContents = fs.readFile(filePath)
		return scriptContents
	end

	if fs.isDir(filePath) then
		if fs.isFile(filePath .. "/init.luau") then
			scriptContents = fs.readFile(filePath .. "/init.luau")
		end

		if fs.isFile(filePath .. "/init.lua") then
			scriptContents = fs.readFile(filePath .. "/init.lua")
		end
	end

	if scriptContents == nil then
		for _, ext in { ".luau", ".lua" } do
			local filePathExt = filePath .. ext
			if fs.isFile(filePathExt) then
				scriptContents = fs.readFile(filePathExt)
			end
		end

		if scriptContents == nil then
			error(`No such file or directory \`{filePath}\``)
		end
	end

	return scriptContents
end

return discoverAndReadScript
