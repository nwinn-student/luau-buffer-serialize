local benchmark = {}

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
  --output=<file>

Luau options:
  --codegen:
  -O<n>:
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

return benchmark
