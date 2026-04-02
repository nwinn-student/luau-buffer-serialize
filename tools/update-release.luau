local update_release = {}

--[[
    Used to update release notes for existing releases to
     contain performance comparisons to the prior version

    To run:
    cd to/repo/path
	lune run tools/update-release.luau v3.0.0 v1.0.0

	Practical use: (recommended to open tmp.md to verify)
	cd to/repo/path
	lune run tools/update-release.luau v3.0.0 > tmp.md
	gh release edit v3.0.0 -F tmp.md
	rm tmp.md
]]

type Notes = {
	body: string,
	ending: string,
}

local process = require("@lune/process")
local serde = require("@lune/serde")

local compare_results
local changelog_string: string = "\n\n\n**Full Changelog**: "

local options = {
	prior_tag = "",
	tag = "",
}

function printHelp()
	print(string.format(
		[[
Usage: %s <current_tag> <prior_tag>

Compares the provided current tag against a prior tag.

Available options:
  -h, --help: Display this usage message
	]],
		process.env._
	))
end
-- we can use gh release view --json body
local function get_release_notes(): Notes
	local release_process: process.ChildProcess = process.create(
		"gh",
		(`release view {options.tag} --json body`):split(" ")
	)

	assert(release_process:status().ok, release_process.stderr:readToEnd())

	local notes: string =
		serde.decode("json", release_process.stdout:readToEnd()).body

	local changelog_split: { string } = notes:split(changelog_string)

	local body: string =
		table.concat(changelog_split, changelog_string, 1, #changelog_split - 1)
	local ending: string = changelog_split[#changelog_split]

	return {
		body = body,
		ending = ending,
	}
end

for _, input: string in process.args do
	if input == "-h" or input == "--help" then
		printHelp()
		process.exit(0)
	end
	if options.tag == "" then
		options.tag = input
		continue
	end
	options.prior_tag = input
end
if options.tag == "" then
	print(`tag must be defined, see help:`)
	printHelp()
	process.exit(0)
end

-- Get prior tag first!!!
local release_notes: Notes = get_release_notes()
if options.prior_tag == "" then
	-- https://github.com/{user}/{repo}/compare/{priorTag}...{tag}
	options.prior_tag = release_notes.ending:sub(
		-- fails if repo is named compare or name is compare
		release_notes.ending:find(`/compare/`, nil, true) + 9,
		release_notes.ending:find(`...{options.tag}`, nil, true) - 1
	)
end

do
	local compare_process: process.ChildProcess = process.create(
		"lune",
		(`run tools/compare-results {options.tag} --versions={options.prior_tag}`):split(
			" "
		)
	)
	assert(compare_process:status().ok, compare_process.stderr:readToEnd())
	compare_results = serde.decode("json", compare_process.stdout:readToEnd())

	-- What if instead of erroring we line up the entire process?
	-- lune run tools/fetch-resources --versions=previous_tag
	-- lune run tools/generate-scripts --versions=previous_tag
	-- lune run tools/benchmark results/BufferSerializer
	assert(
		compare_results.serialize[options.prior_tag],
		`{options.prior_tag} has not been benchmarked`
	)
end

if compare_results then
	local serialize = compare_results.serialize[options.prior_tag]
	local deserialize = compare_results.deserialize[options.prior_tag]

	local compare_string = "\n"

	compare_string ..= "**Serialize**\n"
	local ordered = {
		"time",
		"space",
		"size",
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

	local contents: string =
		`{release_notes.body}\n{compare_string}{changelog_string}{release_notes.ending}`

	print(contents)
end

return update_release
