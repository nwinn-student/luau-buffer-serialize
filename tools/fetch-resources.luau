--[[
	Used to download the datasets and luau-bench used to benchmark

	- The source and taxonomy of the datasets is also downloaded
	- Optimized to use minimal GitHub API requests.
	 - 1 request for datasets
	 - 1 request for luau-bench
	 - 1 request for all versions (1 per 30)
	 - 0 requests for individual versions

	Places the resources in the resources directory.
	- /resources
	 - pokedex.json
	 - /size_datasets
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

function cli_assert(cond: any, message: string)
	if not cond then
		print(message)
		process.exit(0)
	end
end

function printHelp()
	print([[
Usage: lune run tools/fetch-resources [options]

Fetches datasets and luau-bench from GitHub and places them in the `resources` directory.

Available options:
  -h, --help: Display this usage message
  --verisons=<tag[,tag]>: Fetches the versions and puts them into resources/BufferSerializer/{VERSION}
    ALL can be used to get all versions.
  --exclude-datasets: Does not fetch datasets
  --exclude-bench: Does not fetch luau-bench
	]])
end

for _, input: string in process.args do
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

local datasets_root: string =
	"https://api.github.com/repos/jviotti/binary-json-size-benchmark/contents"
local raw_datasets_root: string =
	"https://raw.github.com/jviotti/binary-json-size-benchmark/main"
local bench_root: string =
	"https://api.github.com/repos/nwinn-student/luau-bench/contents"
local bs_pre_root: string =
	"https://api.github.com/repos/nwinn-student/luau-buffer-serialize"
local raw_bs_root: string =
	"https://raw.github.com/nwinn-student/luau-buffer-serialize"
local cached_bs = {
	"boolean",
	"buffer",
	"inflate",
	"init",
	"link", -- not in all
	"nil",
	"number",
	"string",
	"table",
	"userdata",
	"vector",
	-- add more as needed
}

local function ghrequest(
	url: string,
	root: string,
	query: { [string]: string }?
): net.FetchResponse
	return net.request({
		url = `{root}/{url}`,
		query = query,
		headers = {
			["X-GitHub-Api-Version"] = "2022-11-28",
		},
	})
end

local function get_content(path: string): string
	local results: net.FetchResponse = net.request(path)

	assert(results.ok, `failure to get content for {path}`)

	return results.body
end

local function set_content(
	file_path: string,
	url_path: string,
	should_not_assert: boolean?
): ()
	task.spawn(function(): ()
		local success: boolean, contents: string = pcall(get_content, url_path)

		if not success then
			if should_not_assert then
				return
			end
			cli_assert(true, contents)
		end

		fs.writeFile(file_path, contents)
	end)
end

local function fetch_size_datasets(): ()
	print("FETCHING SIZE DATASETS...")

	local success: boolean, dataset_result =
		pcall(ghrequest, "benchmark", datasets_root)

	-- is requestResult valuable?
	cli_assert(success, tostring(dataset_result)) -- no connection
	cli_assert(dataset_result.ok, `failure to get content from dataset benchmark`)

	local datasetDirs = serde.decode("json", dataset_result.body)

	if not fs.isDir("resources/size_datasets") then
		fs.writeDir("resources/size_datasets")
	end

	-- The dataset repo is a public archive, so we can make the
	-- assumption that all file locations are stationary

	for _, dir: GitHubResult in datasetDirs do
		if not fs.isDir(`resources/size_datasets/{dir.name}`) then
			fs.writeDir(`resources/size_datasets/{dir.name}`)
		end

		local data_url: string = `{raw_datasets_root}/{dir.path}/document.json`
		local taxonomy_url: string = `{raw_datasets_root}/{dir.path}/TAXONOMY`
		local source_url: string = `{raw_datasets_root}/{dir.path}/SOURCE`

		set_content(`resources/size_datasets/{dir.name}/document.json`, data_url)
		set_content(`resources/size_datasets/{dir.name}/TAXONOMY`, taxonomy_url)
		set_content(`resources/size_datasets/{dir.name}/SOURCE`, source_url)
	end
end

local function fetch_pokedex_dataset(): ()
	print("FETCHING POKEDEX DATASET...")

	-- Note: We are using a blob link instead of the actual link:
	-- https://raw.githubusercontent.com/Biuni/PokemonGO-Pokedex/master/pokedex.json
	-- to avoid cases where the user is comprimised and the json is modified.

	set_content(
		"resources/pokedex.json",
		"https://raw.githubusercontent.com/Biuni/PokemonGO-Pokedex/ee19a4e93d9df10783a4d04c5245ab4cb8810861/pokedex.json"
	)
end

local function fetch_bench(): ()
	print("FETCHING LUAU-BENCH...")

	local success: boolean, bench_result = pcall(ghrequest, "src", bench_root)

	-- is requestResult valuable?
	cli_assert(success, tostring(bench_result)) -- connection based
	cli_assert(bench_result.ok, `failure to get content from luau-bench src`)

	local benchDirs = serde.decode("json", bench_result.body)

	if not fs.isDir("resources/luau-bench") then
		fs.writeDir("resources/luau-bench")
	end

	for _, dir: GitHubResult in benchDirs do
		set_content(`resources/luau-bench/{dir.name}`, dir.download_url)
	end
end

local function fetch_tag(version: string): ()
	if not fs.isDir(`resources/BufferSerializer/{version}`) then
		fs.writeDir(`resources/BufferSerializer/{version}`)
	end

	for _, name: string in cached_bs do
		set_content(
			`resources/BufferSerializer/{version}/{name}.luau`,
			`{raw_bs_root}/{version}/src/{name}.luau`,
			true
		)
	end
end

-- Actual fetching

if not fs.isDir("resources") then
	fs.writeDir("resources")
end

if not options.exclude_datasets then
	fetch_size_datasets()
	fetch_pokedex_dataset()
end

if not options.exclude_bench then
	fetch_bench()
end

for _, version: string in options.versions do
	if version == "ALL" then
		print("FETCHING ALL VERSIONS...")
		local list_version_result: net.FetchResponse =
			ghrequest("releases", bs_pre_root)

		cli_assert(
			list_version_result.ok,
			`failure to get content from bufferserializer releases`
		)

		local listversionDirs = serde.decode("json", list_version_result.body)
		for _, version in listversionDirs do
			fetch_tag(version.tag_name)
		end

		local page: number = 1
		local next_list_version_result: net.FetchResponse = list_version_result
		while true do
			if not next_list_version_result.headers.link then
				break
			end

			page += 1
			next_list_version_result =
				ghrequest("releases", bs_pre_root, { page = page })
			cli_assert(
				next_list_version_result.ok,
				`failure to get content from bufferserializer releases (page {page})`
			)
			local next_listversionDirs =
				serde.decode("json", next_list_version_result.body)
			for _, version in next_listversionDirs do
				fetch_tag(version.tag_name)
			end
		end

		break
	end

	print(`FETCHING {version}...`)
	fetch_tag(version)
end

return {}
