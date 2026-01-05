--[[
	Compares the results for BufferSerializer
	- Recommended to pipe the results into a file (JSON format)

	To run:

	lune run tools/compare-results.luau --versions=ALL > compare-results.json
]]

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")

local options = {
	versions = {},
	all_versions = false,
}

function printHelp()
	print(string.format(
		[[
Usage: %s [options] <name>

Available options:
  -h, --help: Display this usage message
  --versions<tag[,tag]>: Compares the versions
    ALL can be used to get all versions.
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
	options.name = input
end

assert(
	fs.isFile(options.name or "benchmark-results.json"),
	`results not found ({options.name or "benchmark-results.json"})`
)

local data: { [string]: VersionData } = serde.decode(
	"json",
	fs.readFile(options.name or "benchmark-results.json")
).BufferSerializer

local current_data: VersionData = {
	serialize = data.serialize,
	deserialize = data.deserialize,
	size = data.size,
}

data.serialize = nil
data.deserialize = nil
data.size = nil

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
		[string]: SerialFormat & Metadata<{ pair: SerialFormat }>,
	},
	deserialize: {
		[string]: CategoryData & Metadata<{ pair: BenchFormat }>,
	},
	size: {
		[string]: CategoryData & Metadata<{
			size: number,
			pair_size: number,
			compression: {
				gzip: number,
				lz4: number,
				pair_gzip: number,
				pair_lz4: number,
			},
		}>,
	},
}

local compare_info = {
	serialize = {},
	deserialize = {},
	size = {},
	pair = {
		serialize = {},
		deserialize = {},
	},
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

-- Uncertain what we need from this
local function size_compare(version: string?, version_data: VersionData)
	if not version then
		version = "CURRENT"
	end

	compare_info.size[version] = {}

	for dataset, results in version_data.size do
		compare_info.size[version][dataset] = {
			BufferSerializer = {
				uncompressed = results.metadata.size,
				gzip = results.metadata.compression.gzip,
				lz4 = results.metadata.compression.lz4,
			},
			["BufferSerializer (paired)"] = {
				uncompressed = results.metadata.pair_size,
				gzip = results.metadata.compression.pair_gzip,
				lz4 = results.metadata.compression.pair_lz4,
			},
		}
	end
end

-- pair is N% better
local function pair_compare(version: string?, version_data: VersionData)
	if not version then
		version = "CURRENT"
	end

	local count_categories = {}
	local result_categories = {
		time = {},
		space = {},
		size = {},
	}

	-- setup count
	for dataset, results in version_data.serialize do
		local category = results.metadata.taxonomy
		count_categories[category] = (count_categories[category] or 0) + 1

		for _, value in result_categories do
			value[category] = 0
		end
	end

	for dataset, results in version_data.serialize do
		local category = results.metadata.taxonomy

		populate_changes(
			result_categories,
			category,
			results,
			results.metadata.pair
		)
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

	compare_info.pair.serialize[version] = {
		time = process_results("time", result_categories.time.ALL),
		space = process_results("space", result_categories.space.ALL),
		size = process_results("size", result_categories.size.ALL),

		per_category = {},
	}

	-- process per-category
	for category, count in count_categories do
		local per_category = compare_info.pair.serialize[version].per_category

		local category_table = {}
		per_category[category] = category_table

		category_table.time =
			process_results("time", result_categories.time[category] / count)
		category_table.space =
			process_results("space", result_categories.space[category] / count)
		category_table.size =
			process_results("size", result_categories.size[category] / count)
	end

	-- setup count
	for dataset, results in version_data.serialize do
		local category = results.metadata.taxonomy
		count_categories[category] = (count_categories[category] or 0) + 1

		for _, value in result_categories do
			value[category] = 0
		end
	end

	for dataset, results in version_data.deserialize do
		local category = results.metadata.taxonomy

		populate_changes(
			result_categories,
			category,
			results,
			results.metadata.pair
		)
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

	compare_info.pair.deserialize[version] = {
		time = process_results("time", result_categories.time.ALL),
		space = process_results("space", result_categories.space.ALL),

		per_category = {},
	}

	-- process per-category
	for category, count in count_categories do
		local per_category = compare_info.pair.deserialize[version].per_category

		local category_table = {}
		per_category[category] = category_table

		category_table.time =
			process_results("time", result_categories.time[category] / count)
		category_table.space =
			process_results("space", result_categories.space[category] / count)
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
	local pair_categories = {
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
		for _, value in pair_categories do
			value[category] = 0
		end
	end

	for dataset, results in current_data.serialize do
		local version_results = version_data.serialize[dataset]

		local category = results.metadata.taxonomy

		populate_changes(result_categories, category, version_results, results)
		populate_changes(
			pair_categories,
			category,
			version_results.metadata.pair,
			results.metadata.pair
		)
	end

	do
		local sum_count_categories = sum(count_categories)

		result_categories.time.ALL = sum(result_categories.time)
			/ sum_count_categories
		result_categories.space.ALL = sum(result_categories.space)
			/ sum_count_categories
		result_categories.size.ALL = sum(result_categories.size)
			/ sum_count_categories

		pair_categories.time.ALL = sum(pair_categories.time)
			/ sum_count_categories
		pair_categories.space.ALL = sum(pair_categories.space)
			/ sum_count_categories
		pair_categories.size.ALL = sum(pair_categories.size)
			/ sum_count_categories
	end

	compare_info.serialize[version] = {
		time = process_results("time", result_categories.time.ALL),
		space = process_results("space", result_categories.space.ALL),
		size = process_results("size", result_categories.size.ALL),

		pair_time = process_results("pair time", pair_categories.time.ALL),
		pair_space = process_results("pair space", pair_categories.space.ALL),
		pair_size = process_results("pair size", pair_categories.size.ALL),

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

		category_table.pair_time =
			process_results("pair time", pair_categories.time[category] / count)
		category_table.pair_space =
			process_results("pair space", pair_categories.space[category] / count)
		category_table.pair_size =
			process_results("pair size", pair_categories.size[category] / count)
	end

	table.clear(count_categories) -- could differ

	-- setup count
	for dataset, results in current_data.deserialize do
		local category = results.metadata.taxonomy
		count_categories[category] = (count_categories[category] or 0) + 1

		for _, value in result_categories do
			value[category] = 0
		end
		for _, value in pair_categories do
			value[category] = 0
		end
	end

	for dataset, results in current_data.deserialize do
		local version_results = version_data.deserialize[dataset]

		local category = results.metadata.taxonomy

		populate_changes(result_categories, category, version_results, results)
		populate_changes(
			pair_categories,
			category,
			version_results.metadata.pair,
			results.metadata.pair
		)
	end

	do
		local sum_count_categories = sum(count_categories)

		result_categories.time.ALL = sum(result_categories.time)
			/ sum_count_categories
		result_categories.space.ALL = sum(result_categories.space)
			/ sum_count_categories

		pair_categories.time.ALL = sum(pair_categories.time)
			/ sum_count_categories
		pair_categories.space.ALL = sum(pair_categories.space)
			/ sum_count_categories
	end

	compare_info.deserialize[version] = {
		time = process_results("time", result_categories.time.ALL),
		space = process_results("space", result_categories.space.ALL),

		pair_time = process_results("pair time", pair_categories.time.ALL),
		pair_space = process_results("pair space", pair_categories.space.ALL),

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

		category_table.pair_time =
			process_results("pair time", pair_categories.time[category] / count)
		category_table.pair_space =
			process_results("pair space", pair_categories.space[category] / count)
	end

	-- now we need to do size stuff..
	size_compare(version, version_data)
end

size_compare(nil, current_data)
pair_compare(nil, current_data)

-- Attempt to compare each version to the current
if options.all_versions then
	for version, version_data in data do
		version_compare(version, version_data)
		pair_compare(version, version_data)
	end
end
for _, version in options.versions do
	local version_data = data[version]

	version_compare(version, version_data)
	pair_compare(version, version_data)
end

print(serde.encode("json", compare_info, true)) -- !!!!PIPE IT INTO A FILE!!!!

return compare_info
