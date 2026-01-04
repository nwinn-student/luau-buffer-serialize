local release = {}

--[[
	Used to add releases to Github, assumes user is logged into gh

	To run:
	cd to/repo/path
	lune run tools/release.luau 1.2.3 \
		--build --delete-build \
		--prefix=BufferSerializer

	Alternative:
	cd to/repo/path
	lune run tools/build.luau --name=BufferSerializerTAG
	gh release create vTAG \
		--generate-notes --discussion-category Announcements \
		--fail-on-no-commits --title Version TAG \
		BufferSerializerTAG.rbxm
]]

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")

local tag_name: string -- updated later
local compare_results

local function pathName(path: string)
	local pathSplit = string.split(path, "/")
	return pathSplit[#pathSplit - 1]
end

local options = {
	build = false,
	tag = "",
	prefix = pathName(process.cwd),
	delete = false,
}

function printHelp()
	print(string.format(
		[[
Usage: %s <tag> [options]

Available options:
  -h, --help: Display this usage message
  --build: Uses build.luau to build
  --prefix<=str>: The prefix of the file to publish, default is directory name
  --delete-build: Deletes the build file after publishing the Release
	]],
		process.env._
	))
end

for _, input in process.args do
	if input == "-h" or input == "--help" then
		printHelp()
		process.exit(0)
	end
	if input:sub(1, 9) == "--prefix=" then
		options.prefix = input:sub(10)
		continue
	end
	if input == "--build" then
		options.build = true
		continue
	end
	if input == "--delete-build" then
		options.delete = true
		continue
	end
	options.tag = input
end
if options.tag == "" then
	print(`tag must be defined, see help:`)
	printHelp()
	process.exit(0)
end
tag_name = `v{options.tag}`

if options.build then
	local build_process = process.exec("lune", {
		"run",
		"tools/build.luau",
		`--name={options.prefix}{options.tag}`,
	})
	assert(build_process.ok, build_process.stderr)
end

do
	local tag_process =
		process.create("gh", ("release view --json tagName"):split(" "))

	assert(tag_process:status().ok, tag_process.stderr:readToEnd())

	local tag_output = serde.decode("json", tag_process.stdout:readToEnd())

	local previous_tag = tag_output.tagName

	local compare_process = process.create(
		"lune",
		(`run tools/compare-results --versions={previous_tag}`):split(" ")
	)
	if compare_process:status().ok then
		compare_results = serde.decode("json", compare_process.stdout:readToEnd())

		-- What if instead of erroring we line up the entire process?
		-- lune run tools/fetch-resources --versions=previous_tag
		-- lune run tools/generate-scripts --versions=previous_tag
		-- lune run tools/benchmark results/BufferSerializer
		assert(
			compare_results.serialize[previous_tag],
			`{previous_tag} has not been benchmarked`
		)
	end
end

do
	local ghRelease = process.exec("gh", {
		"release",
		"create",
		tag_name,
		"--generate-notes",
		"--discussion-category",
		"Announcements",
		"--fail-on-no-commits",
		"--title",
		`Version {options.tag}`,
		-- If lune fails, this will fail too
		`{options.prefix}{options.tag}.rbxm`,
	})

	if options.delete and fs.isFile(`{options.prefix}{options.tag}.rbxm`) then
		fs.removeFile(`{options.prefix}{options.tag}.rbxm`)
	end
	assert(ghRelease.ok, ghRelease.stderr)
end

-- we can use gh release view --json body
local function get_release_notes()
	local release_process =
		process.create("gh", ("release view --json body"):split(" "))

	assert(release_process:status().ok, release_process.stderr:readToEnd())

	return serde.decode("json", release_process.stdout:readToEnd()).body
end

-- and gh release edit options.tag -F release-notes.md
local function edit_release_notes()
	local edit_process = process.create(
		"gh",
		("release edit options.tag -F temp-release-notes.md"):split(" ")
	)
	assert(edit_process:status().ok, edit_process.stderr:readToEnd())
end

if compare_results then
	assert(
		not fs.isFile("temp-release-notes.md"),
		"release uses temp-release-notes.md to store GitHub Generated Release Notes temporarily"
	)

	local release_notes = get_release_notes()

	local changelog_string = "\n\n\n**Full Changelog**: "
	local changelog_split = release_notes:split(changelog_string)

	local body =
		table.concat(changelog_split, changelog_string, 1, #changelog_split - 1)
	local ending = changelog_split[#changelog_split]

	local serialize = compare_results.serialize[tag_name]
	local deserialize = compare_results.deserialize[tag_name]

	local compare_string = "\n"

	compare_string ..= "**Serialize**\n"
	local ordered = {
		"time",
		"pair_time",
		"space",
		"pair_space",
		"size",
		"pair_size",
	}
	table.sort(ordered, function(a0, a1): boolean
		return a0 > a1
	end)
	for _, key in ordered do
		local msg = serialize[key]
		if type(msg) == "string" then
			compare_string ..= `* {msg}\n`
		end
	end

	compare_string ..= "\n**Deserialize**\n"
	for _, key in ordered do
		local msg = deserialize[key]
		if type(msg) == "string" then
			compare_string ..= `* {msg}\n`
		end
	end

	compare_string ..= "<details><summary>Per Category</summary>\n\n"
	compare_string ..= "**Serialize**\n\n| Category | Results |\n|--|--|\n"

	local ordered_categories = {}
	for category in serialize.per_category do
		table.insert(ordered_categories, category)
	end
	table.sort(ordered_categories, function(a0, a1): boolean
		return a0 < a1
	end)
	for _, category in ordered_categories do
		local results = serialize.per_category[category]
		local results_string = ""
		for _, key in ordered do
			local msg = results[key]
			if type(msg) == "string" then
				results_string ..= `{msg}<br/>`
			end
		end

		compare_string ..= `| {category} | {results_string:sub(1, -6)} |\n`
	end
	table.clear(ordered_categories) -- could differ?

	compare_string ..= "\n**Deserialize**\n\n| Category | Results |\n|--|--|\n"

	for category in deserialize.per_category do
		table.insert(ordered_categories, category)
	end
	table.sort(ordered_categories, function(a0, a1): boolean
		return a0 < a1
	end)
	for _, category in ordered_categories do
		local results = deserialize.per_category[category]
		local results_string = ""
		for _, key in ordered do
			local msg = results[key]
			if type(msg) == "string" then
				results_string ..= `{msg}<br/>`
			end
		end

		compare_string ..= `| {category} | {results_string:sub(1, -6)} |\n`
	end
	compare_string ..= "\n</details>"

	local contents = `{body}\n{compare_string}{changelog_string}{ending}`

	fs.writeFile("temp-release-notes.md", contents)

	edit_release_notes()

	fs.removeFile("temp-release-notes.md")
end

return release
