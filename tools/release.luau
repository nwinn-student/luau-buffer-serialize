local release = {}

--[[
	Used to add releases to Github, assumes user is logged into gh

	To run:
	cd to/repo/path
	lune run tools/release.luau TAG \
		--build

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

local options = {
	build = false,
	tag = "",
}

function printHelp()
	print(string.format(
		[[
Usage: %s <tag> [options]

Available options:
  -h, --help: Display this usage message
  --build: Uses build.luau to build
	]],
		process.env._
	))
end

for _, input in args do
	if input == "-h" or input == "--help" then
		printHelp()
		process.exit(0)
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
		"--name=BufferSerializer" .. options.tag,
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
	`BufferSerializer{options.tag}.rbxm`,
})
print(ghRelease.stderr)

return release
