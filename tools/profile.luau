local profile = {}

--[[
	Used to create profile SVGs
	Requires python installed

	To run:
	cd to/repo/path
	lune run tools/profile.luau bench/profile.luau

	[Optional] If using bash, open using:
	start profile.svg
]]

local fs = require("@lune/fs")
local process = require("@lune/process")

local args = process.args

local options = {
	file = "tools/profile-bs.luau",
}

function printHelp()
	print(string.format(
		[[
Usage: %s <file>

Requires luau and python installed.

Available options:
  -h, --help: Display this usage message
	]],
		process.env._
	))
end

for _, input in args do
	if input == "-h" or input == "--help" then
		printHelp()
		process.exit(0)
	end
	options.file = input
end

process.exec("luau", {
	"--profile",
	options.file,
})

-- Generate SVG
local svg = process.exec("python", {
	"tools/perfgraph.py",
	"profile.out",
})

assert(svg.ok, svg.stderr)

fs.writeFile("profile.svg", svg.stdout)

-- Cleanup of temp files
fs.removeFile("profile.out")

return profile
