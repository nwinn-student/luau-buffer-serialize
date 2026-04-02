--[[
	Compares the results for BufferSerializer
	- Recommended to pipe the results into a file (JSON format)

	To run:

	lune run tools/compare-results.luau --versions=ALL > compare-results.json
]]

type BenchData = {
	average: number,
	stdev: number,

	min: number,
	median: number,
	max: number,

	iqr: number,

	hist: { [string]: number },
}
type BenchFormat = { time: BenchData, space: BenchData }

type Metadata<T> = { metadata: T }

type CategoryData = BenchFormat & Metadata<{ taxonomy: string }>
type SerialFormat = CategoryData & Metadata<{ size: number }>

type VersionData = {
	serialize: {
		[string]: SerialFormat,
	},
	deserialize: {
		[string]: CategoryData,
	},
	size: {
		[string]: CategoryData & Metadata<{
			size: number,
			compression: {
				gzip: number,
				lz4: number,
			},
		}>,
	},
}

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")

local options = {
	versions = {} :: { string },
	all_versions = false,
	tag = "CURRENT",
	fileName = "benchmark-results.json",
}

function printHelp()
	print(string.format(
		[[
Usage: %s [options] <tag>

Available options:
  -h, --help: Display this usage message
  --versions=<tag[,tag]>: Compares provided version against the versions
    ALL can be used to get all versions.
  --file=<fileName>: The file containing the benchmark results
    Defaults to benchmark-results.json
	]],
		process.env._
	))
end

for _, input in process.args do
	if input == "-h" or input == "--help" then
		printHelp()
		process.exit(0)
	end
	if input:sub(1, 11) == "--versions=" then
		options.versions = input:sub(12):split(",")
		for _, version in options.versions do
			if version == "ALL" then
				options.all_versions = true
				table.clear(options.versions)
				break
			end
		end
		continue
	end
	if input:sub(1, 7) == "--file=" then
		options.fileName = input
		continue
	end
	options.tag = input
end

assert(fs.isFile(options.fileName), `results not found ({options.fileName})`)

-- TODO: Add proper error msgs for when serde.decode is not a table.
local data: { [string]: VersionData } =
	serde.decode("json", fs.readFile(options.fileName)).BufferSerializer

local current_data: VersionData = {}
if options.tag == "CURRENT" then
	current_data.deserialize = data.deserialize
	current_data.serialize = data.serialize
	current_data.size = data.size
else
	current_data.deserialize = data[options.tag].deserialize
	current_data.serialize = data[options.tag].serialize
	current_data.size = data[options.tag].size

	data[options.tag] = nil
end

data.serialize = nil
data.deserialize = nil
data.size = nil

local compare_info = {
	serialize = {},
	deserialize = {},
	size = {},
}

local function sum(tab: { [any]: number })
	local total = 0
	for _, value: number in tab do
		total += value
	end
	return total
end

local function percentage_change(first: number, second: number)
	if second == 0 or not second then
		if first == 0 or not first then
			return 0
		end
		return -1 * percentage_change(second, first)
	end
	return 100 * (first - second) / second
end

local function process_results(msg: string, avg_perc: number)
	if avg_perc == 0 then
		--return ("Unchanged %s"):format(msg)
		return
	end
	local optim = if avg_perc > 0 then "Optimized" else "Regressed"

	return ("%s %s (%.2f%%)"):format(optim, msg, avg_perc)
end

local function populate_changes(
	result_categories: {
		time: { [string]: number },
		space: { [string]: number },
		size: { [string]: number },
	},
	category: string,
	from: SerialFormat,
	against: SerialFormat
)
	result_categories.time[category] += percentage_change(
		from.time.median,
		against.time.median
	)
	result_categories.space[category] += percentage_change(
		from.space.average,
		against.space.average
	)

	if from.metadata and against.metadata then
		result_categories.size[category] += percentage_change(
			from.metadata.size,
			against.metadata.size
		)
	end
end

local function size_compare(version: string?, version_data: VersionData)
	if not version then
		version = "CURRENT"
	end

	compare_info.size[version] = {}

	for dataset, results in version_data.size do
		-- NOTE: There is no longer a need to wrap BufferSerializer
		--  in a table, we can just store uncompressed, gzip, and lz4
		compare_info.size[version][dataset] = {
			BufferSerializer = {
				uncompressed = results.metadata.size,
				gzip = results.metadata.compression.gzip,
				lz4 = results.metadata.compression.lz4,
			},
		}
	end
end

-- current is N% better
local function version_compare(version: string, version_data: VersionData)
	local count_categories = {}
	local result_categories = {
		time = {},
		space = {},
		size = {},
	}

	-- setup count
	for dataset, results in current_data.serialize do
		local category = results.metadata.taxonomy
		count_categories[category] = (count_categories[category] or 0) + 1

		for _, value in result_categories do
			value[category] = 0
		end
	end

	for dataset, results in current_data.serialize do
		local version_results = version_data.serialize[dataset]

		local category = results.metadata.taxonomy

		populate_changes(result_categories, category, version_results, results)
	end

	do
		local sum_count_categories = sum(count_categories)

		result_categories.time.ALL = sum(result_categories.time)
			/ sum_count_categories
		result_categories.space.ALL = sum(result_categories.space)
			/ sum_count_categories
		result_categories.size.ALL = sum(result_categories.size)
			/ sum_count_categories
	end

	compare_info.serialize[version] = {
		time = process_results("time", result_categories.time.ALL),
		space = process_results("space", result_categories.space.ALL),
		size = process_results("size", result_categories.size.ALL),

		per_category = {},
	}

	-- process per-category
	for category, count in count_categories do
		local per_category = compare_info.serialize[version].per_category

		local category_table = {}
		per_category[category] = category_table

		category_table.time =
			process_results("time", result_categories.time[category] / count)
		category_table.space =
			process_results("space", result_categories.space[category] / count)
		category_table.size =
			process_results("size", result_categories.size[category] / count)
	end

	table.clear(count_categories) -- could differ

	-- setup count
	for dataset, results in current_data.deserialize do
		local category = results.metadata.taxonomy
		count_categories[category] = (count_categories[category] or 0) + 1

		for _, value in result_categories do
			value[category] = 0
		end
	end

	for dataset, results in current_data.deserialize do
		local version_results = version_data.deserialize[dataset]

		local category = results.metadata.taxonomy

		populate_changes(result_categories, category, version_results, results)
	end

	do
		local sum_count_categories = sum(count_categories)

		result_categories.time.ALL = sum(result_categories.time)
			/ sum_count_categories
		result_categories.space.ALL = sum(result_categories.space)
			/ sum_count_categories
	end

	compare_info.deserialize[version] = {
		time = process_results("time", result_categories.time.ALL),
		space = process_results("space", result_categories.space.ALL),

		per_category = {},
	}

	-- process per-category
	for category, count in count_categories do
		local per_category = compare_info.deserialize[version].per_category

		local category_table = {}
		per_category[category] = category_table

		category_table.time =
			process_results("time", result_categories.time[category] / count)
		category_table.space =
			process_results("space", result_categories.space[category] / count)
	end

	-- now we need to do size stuff..
	size_compare(version, version_data)
end

size_compare(options.tag, current_data)

-- Attempt to compare each version to the current
if options.all_versions then
	for version: string, version_data: VersionData in data do
		version_compare(version, version_data)
	end
end
for _, version: string in options.versions do
	local version_data: VersionData = data[version]

	assert(version_data, `Invalid version "{version}"`)

	version_compare(version, version_data)
end

print(serde.encode("json", compare_info, true)) -- !!!!PIPE IT INTO A FILE!!!!

return compare_info
