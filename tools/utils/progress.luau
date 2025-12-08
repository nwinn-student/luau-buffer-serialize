local progress = {}

local resetToStart = "\r\b\r\b\r\b\r"

function progress.new(totalTasks: number)
	local display = ""
	local counter = {
		completed = 0,
	}

	local startTime = os.clock()
	print()
	print()

	function counter:run(msg: string)
		display = "[  Running  ] " .. msg
		print(resetToStart)
		print(display)

		local bar = (">"):rep((counter.completed / totalTasks) * 34 // 1)
		bar ..= (" "):rep(34 - #bar)

		local duration = (100 * (os.clock() - startTime) // 1) / 100

		print(`{bar} | {duration} s`)
	end
	function counter:complete(msg: string)
		counter.completed += 1

		if counter.completed == totalTasks then
			print(resetToStart)
			-- fill old with spaces
			print("\1b[2k\n\1b[2k")
			print(resetToStart)
			display = nil
		end
	end

	return counter
end

return progress
