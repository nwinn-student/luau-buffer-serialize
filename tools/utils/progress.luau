local progress = {}

--[[
	Handles a printed progress bar that updates
	 each time run/complete are called
]]
export type Progress = {
	--[[
		Declares that the item is running
	]]
	run: (itemName: string) -> (),
	--[[
		Declares that the item has completed running,
		 updating the progress bar.
	]]
	complete: (itemName: string) -> (),
}

local resetToStart: string = "\x1B[3F"

--[[
	Creates a new Progress object that will process at most
	 the provided value of tasks.
]]
function progress.new(totalTasks: number): Progress
	local display: string = ""
	local completed: number = 0
	local startTime: number = os.clock()
	print()
	print()

	local counter: Progress = {}
	function counter:run(itemName: string)
		display = "[  Running  ] " .. itemName
		print(resetToStart)
		print(display)

		local bar: string = (">"):rep((completed / totalTasks) * 34 // 1)
		bar ..= (" "):rep(34 - #bar)

		local duration: number = (100 * (os.clock() - startTime) // 1) / 100

		print(`{bar} | {duration} s`)
	end
	function counter:complete(itemName: string)
		completed += 1

		print(resetToStart)
		print("\r\x1b[2K\n") -- clear running line

		if completed == totalTasks then
			print(resetToStart)
			print("\x1b[2K\n\x1b[2K") -- clear old
			print(resetToStart)
			display = nil

			print(`TOTAL TIME TAKEN: {os.clock() - startTime} s`)
		end
		assert(
			completed <= totalTasks,
			`Improper task count: expected {totalTasks} ({itemName} caused the overflow)`
		)
	end

	return counter
end

return progress
