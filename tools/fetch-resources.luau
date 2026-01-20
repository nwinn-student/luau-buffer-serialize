--[[
	Used to download the datasets and luau-bench used to benchmark

	- The source and taxonomy of the datasets is also downloaded
	- Optimized to use minimal GitHub API requests.
	 - 1 request for datasets
	 - 1 request for luau-bench
	 - [OPTIONAL] 1 request per version

	Places the resources in the resources directory.
	- /resources
	 - /datasets
	 - /luau-bench
	 - /BufferSerializer/{VERSION_TAG}

	To run:
	cd to/repo/path

	lune run tools/fetch-resources --versions=ALL

	It is recommended that subsequent runs be the below to avoid excessive API calls.

	lune run tools/fetch-resources --exclude-datasets --exclude-bench --version=v1.2.3
]]

local fs = require("@lune/fs")
local net = require("@lune/net")
local process = require("@lune/process")
local serde = require("@lune/serde")
local task = require("@lune/task")

type GitHubResult = {
	name: string,
	path: string,
	sha: string,
	size: number,
	type: string,
	url: string,
	download_url: string,
}

local options = {
	versions = {},
	exclude_datasets = false,
	exclude_bench = false,
}

function printHelp()
	print(string.format(
		[[
Usage: %s [options]

Fetches datasets and luau-bench from GitHub.

Available options:
  -h, --help: Display this usage message
  --verisons=<tag[,tag]>: Fetches the versions and puts them into resources/BufferSerializer/{VERSION}
    ALL can be used to get all versions.
  --exclude-datasets: Does not fetch datasets
  --exclude-bench: Does not fetch luau-bench
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
		continue
	end
	if input:sub(1, 18) == "--exclude-datasets" then
		options.exclude_datasets = true
		continue
	end
	if input:sub(1, 15) == "--exclude-bench" then
		options.exclude_bench = true
		continue
	end
	print(`{input} is not a valid command, see help:`)
	printHelp()
	process.exit(0)
end

local datasets_root =
	"https://api.github.com/repos/jviotti/binary-json-size-benchmark/contents"
local raw_datasets_root =
	"https://raw.github.com/jviotti/binary-json-size-benchmark/main"
local bench_root =
	"https://api.github.com/repos/nwinn-student/luau-bench/contents"
local bs_pre_root =
	"https://api.github.com/repos/nwinn-student/luau-buffer-serialize"

local function ghrequest(url: string, root: string)
	return net.request({
		url = `{root}/{url}`,
		headers = {
			["X-GitHub-Api-Version"] = "2022-11-28",
		},
	})
end

local function get_content(path: string)
	local results = net.request(path)

	assert(results.ok, `failure to get content for {path}`)

	return results.body
end

-- Much faster since it is concurrent
local function set_content(file_path: string, url_path: string)
	task.spawn(function()
		local contents = get_content(url_path)

		fs.writeFile(file_path, contents)
	end)
end

local function fetch_dataset()
	print("FETCHING DATASET...")

	local success, dataset_result = pcall(ghrequest, "benchmark", datasets_root)

	if not success then
		print(tostring(dataset_result))
		process.exit(1)
		-- is requestResult valuable?
		--error("turn on your network connection")
	end

	assert(dataset_result.ok, `failure to get content from dataset benchmark`)

	local datasetDirs = serde.decode("json", dataset_result.body)

	if not fs.isDir("resources/datasets") then
		fs.writeDir("resources/datasets")
	end

	-- The dataset repo is a public archive, so we can make the
	-- assumption that all file locations are stationary

	for _, dir: GitHubResult in datasetDirs do
		if not fs.isDir(`resources/datasets/{dir.name}`) then
			fs.writeDir(`resources/datasets/{dir.name}`)
		end

		local data_url = `{raw_datasets_root}/{dir.path}/document.json`
		local taxonomy_url = `{raw_datasets_root}/{dir.path}/TAXONOMY`
		local source_url = `{raw_datasets_root}/{dir.path}/SOURCE`

		set_content(`resources/datasets/{dir.name}/document.json`, data_url)
		set_content(`resources/datasets/{dir.name}/TAXONOMY`, taxonomy_url)
		set_content(`resources/datasets/{dir.name}/SOURCE`, source_url)
	end
end

local function fetch_bench()
	print("FETCHING LUAU-BENCH...")

	local success, bench_result = pcall(ghrequest, "src", bench_root)

	if not success then
		print(tostring(bench_result))
		process.exit(1)
		-- is requestResult valuable?
		--error("turn on your network connection")
	end

	assert(bench_result.ok, `failure to get content from luau-bench src`)

	local benchDirs = serde.decode("json", bench_result.body)

	if not fs.isDir("resources/luau-bench") then
		fs.writeDir("resources/luau-bench")
	end

	for _, dir: GitHubResult in benchDirs do
		set_content(`resources/luau-bench/{dir.name}`, dir.download_url)
	end
end

local function fetch_tag(version: string)
	local version_result = ghrequest(`contents/src?ref={version}`, bs_pre_root)

	assert(
		version_result.ok,
		`failure to get content from bufferserializer src?ref={version}`
	)

	local versionDirs = serde.decode("json", version_result.body)

	if not fs.isDir(`resources/BufferSerializer/{version}`) then
		fs.writeDir(`resources/BufferSerializer/{version}`)
	end

	for _, dir: GitHubResult in versionDirs do
		set_content(
			`resources/BufferSerializer/{version}/{dir.name}`,
			dir.download_url
		)
	end
end

-- Actual fetching

if not fs.isDir("resources") then
	fs.writeDir("resources")
end

if not options.exclude_datasets then
	fetch_dataset()
end

if not options.exclude_bench then
	fetch_bench()
end

for _, version in options.versions do
	if version == "ALL" then
		print("FETCHING ALL VERSIONS...")
		local list_version_result = ghrequest("releases", bs_pre_root)

		assert(
			list_version_result.ok,
			`failure to get content from bufferserializer releases`
		)

		local listversionDirs = serde.decode("json", list_version_result.body)

		for _, version in listversionDirs do
			fetch_tag(version.tag_name)
		end

		break
	end

	print(`FETCHING {version}...`)
	fetch_tag(version)
end

return {}
