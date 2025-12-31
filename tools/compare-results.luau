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

type VData = {
	time: BenchData,
	space: BenchData,
	metadata: {
		taxonomy: string,
	},
}

type VersionData = {
	serialize: {
		[string]: VData & {
			metadata: {
				size: number,
				pair: {
					time: BenchData,
					space: BenchData,
					metadata: { size: number },
				},
			},
		},
	},
	deserialize: {
		[string]: VData & {
			metadata: {
				pair: { time: BenchData, space: BenchData },
			},
		},
	},
	size: {
		[string]: VData & {
			metadata: {
				size: number,
				pair_size: number,
				compression: {
					gzip: number,
					lz4: number,
					pair_gzip: number,
					pair_lz4: number,
				},
			},
		},
	},
}

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
	return 100 * (first - second) / second
end

local function process_results(msg: string, avg_perc: number)
	local optim = if avg_perc > 0 then "Optimized" else "Regressed"

	return ("%s %s (%.2f%%)"):format(optim, msg, avg_perc)
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

local function version_compare(version: string, version_data: VersionData)
	local count_categories = {}
	local result_categories = {
		time = {},
		pair_time = {},
		space = {},
		pair_space = {},
		size = {},
		pair_size = {},
	}

	-- setup count
	for dataset, results in current_data.serialize do
		local category = results.metadata.taxonomy
		count_categories[category] = (count_categories[category] or 0) + 1

		result_categories.time[category] = 0
		result_categories.pair_time[category] = 0
		result_categories.space[category] = 0
		result_categories.pair_space[category] = 0
		result_categories.size[category] = 0
		result_categories.pair_size[category] = 0
	end

	for dataset, results in current_data.serialize do
		local version_results = version_data.serialize[dataset]

		local category = results.metadata.taxonomy

		result_categories.time[category] += percentage_change(
			results.time.average,
			version_results.time.average
		)
		result_categories.pair_time[category] += percentage_change(
			results.metadata.pair.time.average,
			version_results.metadata.pair.time.average
		)
		result_categories.space[category] += percentage_change(
			results.space.average,
			version_results.space.average
		)
		result_categories.pair_space[category] += percentage_change(
			results.metadata.pair.space.average,
			version_results.metadata.pair.space.average
		)
		result_categories.size[category] += percentage_change(
			results.metadata.size,
			version_results.metadata.size
		)
		result_categories.pair_size[category] += percentage_change(
			results.metadata.pair.metadata.size,
			version_results.metadata.pair.metadata.size
		)
	end

	do
		local sum_count_categories = sum(count_categories)

		result_categories.time.ALL = sum(result_categories.time)
			/ sum_count_categories
		result_categories.pair_time.ALL = sum(result_categories.pair_time)
			/ sum_count_categories
		result_categories.space.ALL = sum(result_categories.space)
			/ sum_count_categories
		result_categories.pair_space.ALL = sum(result_categories.pair_space)
			/ sum_count_categories
		result_categories.size.ALL = sum(result_categories.size)
			/ sum_count_categories
		result_categories.pair_size.ALL = sum(result_categories.pair_size)
			/ sum_count_categories
	end

	compare_info.serialize[version] = {
		time = process_results("time", result_categories.time.ALL),
		pair_time = process_results("pair time", result_categories.pair_time.ALL),
		space = process_results("space", result_categories.space.ALL),
		pair_space = process_results(
			"pair space",
			result_categories.pair_space.ALL
		),
		size = process_results("size", result_categories.size.ALL),
		pair_size = process_results("pair size", result_categories.pair_size.ALL),
		per_category = {},
	}

	-- process per-category
	for category, count in count_categories do
		local per_category = compare_info.serialize[version].per_category

		local category_table = {}
		per_category[category] = category_table

		category_table.time =
			process_results("time", result_categories.time[category] / count)
		category_table.pair_time = process_results(
			"pair time",
			result_categories.pair_time[category] / count
		)
		category_table.space =
			process_results("space", result_categories.space[category] / count)
		category_table.pair_space = process_results(
			"pair space",
			result_categories.pair_space[category] / count
		)
		category_table.size =
			process_results("size", result_categories.size[category] / count)
		category_table.pair_size = process_results(
			"pair size",
			result_categories.pair_size[category] / count
		)
	end

	table.clear(count_categories) -- could differ

	-- setup count
	for dataset, results in current_data.serialize do
		local category = results.metadata.taxonomy
		count_categories[category] = (count_categories[category] or 0) + 1

		result_categories.time[category] = 0
		result_categories.pair_time[category] = 0
		result_categories.space[category] = 0
		result_categories.pair_space[category] = 0
	end

	for dataset, results in current_data.deserialize do
		local version_results = version_data.deserialize[dataset]

		local category = results.metadata.taxonomy

		result_categories.time[category] += percentage_change(
			results.time.average,
			version_results.time.average
		)
		result_categories.pair_time[category] += percentage_change(
			results.metadata.pair.time.average,
			version_results.metadata.pair.time.average
		)
		result_categories.space[category] += percentage_change(
			results.space.average,
			version_results.space.average
		)
		result_categories.pair_space[category] += percentage_change(
			results.metadata.pair.space.average,
			version_results.metadata.pair.space.average
		)
	end

	do
		local sum_count_categories = sum(count_categories)

		result_categories.time.ALL = sum(result_categories.time)
			/ sum_count_categories
		result_categories.pair_time.ALL = sum(result_categories.pair_time)
			/ sum_count_categories
		result_categories.space.ALL = sum(result_categories.space)
			/ sum_count_categories
		result_categories.pair_space.ALL = sum(result_categories.pair_space)
			/ sum_count_categories
	end

	compare_info.deserialize[version] = {
		time = process_results("time", result_categories.time.ALL),
		pair_time = process_results("pair time", result_categories.pair_time.ALL),
		space = process_results("space", result_categories.space.ALL),
		pair_space = process_results(
			"pair space",
			result_categories.pair_space.ALL
		),
		per_category = {},
	}

	-- process per-category
	for category, count in count_categories do
		local per_category = compare_info.deserialize[version].per_category

		local category_table = {}
		per_category[category] = category_table

		category_table.time =
			process_results("time", result_categories.time[category] / count)
		category_table.pair_time = process_results(
			"pair time",
			result_categories.pair_time[category] / count
		)
		category_table.space =
			process_results("space", result_categories.space[category] / count)
		category_table.pair_space = process_results(
			"pair space",
			result_categories.pair_space[category] / count
		)
	end

	-- now we need to do size stuff..
	size_compare(version, version_data)
end

size_compare(nil, current_data)

-- Attempt to compare each version to the current
if options.all_versions then
	for version, version_data in data do
		version_compare(version, version_data)
	end
end
for _, version in options.versions do
	local version_data = data[version]

	version_compare(version, version_data)
end

print(serde.encode("json", compare_info, true)) -- !!!!PIPE IT INTO A FILE!!!!

return compare_info
