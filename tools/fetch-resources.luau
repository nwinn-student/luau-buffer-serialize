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

	To run:
	cd to/repo/path

	lune run tools/fetch-resources
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

local datasets_root =
	"https://api.github.com/repos/jviotti/binary-json-size-benchmark/contents"
local raw_datasets_root =
	"https://raw.github.com/jviotti/binary-json-size-benchmark/main"
local bench_root =
	"https://api.github.com/repos/nwinn-student/luau-bench/contents"
local bs_root =
	"https://api.github.com/repos/nwinn-student/luau-buffer-serialize/contents"

local function ghrequest(url: string, root: string): net.FetchResponse
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

if not fs.isDir("resources") or not fs.isDir("resources/datasets") then
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

	-- will not yield!
	set_content(`resources/datasets/{dir.name}/{dir.name}.json`, data_url)
	set_content(`resources/datasets/{dir.name}/TAXONOMY`, taxonomy_url)
	set_content(`resources/datasets/{dir.name}/SOURCE`, source_url)
end

print("FETCHING LUAU-BENCH...")

local bench_result = ghrequest("src", bench_root)

assert(bench_result.ok, `failure to get content from luau-bench src`)

local benchDirs = serde.decode("json", bench_result.body)

if not fs.isDir("resources") or not fs.isDir("resources/luau-bench") then
	fs.writeDir("resources/luau-bench")
end

for _, dir: GitHubResult in benchDirs do
	set_content(`resources/luau-bench/{dir.name}`, dir.download_url)
end

--TODO: Finish version support
-- [[ [OPTIONAL] FETCH VERSION(S) ]] --

local options = {
	versions = {},
}

function printHelp()
	print(string.format(
		[[
Usage: %s [options]

Fetches datasets and luau-bench from GitHub.

Available options:
  -h, --help: Display this usage message
  --verisons=<tag[,tag]>: Fetches the versions and puts them into resources/BufferSerializer{VERSION}
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
	if input:sub(1, 10) == "--version=" then
		options.versions = input:split(",")
		continue
	end
end

-- lune run tools/fetch-resources v123
-- actually.. just do --versions=a,b,c,...
-- it is better.  Could even do ALL (?)

-- if ALL we should use https://api.github.com/repos/nwinn-student/luau-buffer-serialize/releases
-- and loop through each to get the tag_name

for _, version in options.versions do
	local version_result = ghrequest(`src?ref={version}`, bs_root)

	assert(
		bench_result.ok,
		`failure to get content from bufferserializer src?ref={version}`
	)

	local versionDirs = serde.decode("json", version_result.body)

	if
		not fs.isDir("resources")
		or not fs.isDir(`resources/BufferSerializer{version}`)
	then
		fs.writeDir(`resources/BufferSerializer{version}`)
	end

	for _, dir: GitHubResult in versionDirs do
		set_content(
			`resources/BufferSerializer{version}/{dir.name}`,
			dir.download_url
		)
	end
end

return {}
