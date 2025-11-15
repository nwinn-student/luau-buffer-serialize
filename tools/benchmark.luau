local benchmark = {}

local fs = require("@lune/fs")
local process = require("@lune/process")

local args = process.args

local options = {
	file = "",
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
  --codegen:
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
	if input == "--coverage" then
		options.coverage = true
		continue
	end
	-- TODO: Add validity checks
	options.file = input
end

return benchmark
