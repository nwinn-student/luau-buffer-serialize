local release = {}

--[[
	Used to add releases to Github, assumes user is logged into gh

	To run:
	cd to/repo/path
	lune run tools/release.luau 1.2.3 \
		--build \
		--prefix=BufferSerializer

	Alternative:
	cd to/repo/path
	lune run tools/build.luau --name=BufferSerializerTAG
	gh release create vTAG \
		--generate-notes --discussion-category Announcements \
		--fail-on-no-commits --title Version TAG \
		BufferSerializerTAG.rbxm
]]

local process = require("@lune/process")
local args = process.args

local function pathName(path: string)
	local pathSplit = string.split(path, "/")
	return pathSplit[#pathSplit - 1]
end

local options = {
	build = false,
	tag = "",
	prefix = pathName(process.cwd),
}

function printHelp()
	print(string.format(
		[[
Usage: %s <tag> [options]

Available options:
  -h, --help: Display this usage message
  --build: Uses build.luau to build
  --prefix<=str>: The prefix of the file to publish, default is directory name
	]],
		process.env._
	))
end

for _, input in args do
	if input == "-h" or input == "--help" then
		printHelp()
		process.exit(0)
	end
	if input:sub(1, 9) == "--prefix=" then
		options.prefix = input:sub(8)
		continue
	end
	if input == "--build" then
		options.build = true
		continue
	end
	options.tag = input
end
if options.tag == "" then
	print(`tag must be defined, see help:`)
	printHelp()
	process.exit(0)
end

if options.build then
	process.exec("lune", {
		"run",
		"tools/build.luau",
		`--name={options.prefix}{options.tag}`,
	})
end

local ghRelease = process.exec("gh", {
	"release",
	"create",
	`v{options.tag}`,
	"--generate-notes",
	"--discussion-category",
	"Announcements",
	"--fail-on-no-commits",
	"--title",
	`Version {options.tag}`,
	`{options.prefix}{options.tag}.rbxm`,
})
print(ghRelease.stderr)

return release
