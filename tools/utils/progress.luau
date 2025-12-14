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

		print(resetToStart)
		print("\r\x1b[2K\n") -- clear running line

		if counter.completed == totalTasks then
			print(resetToStart)
			print("\x1b[2K\n\x1b[2K") -- clear old
			print(resetToStart)
			display = nil
		end
	end

	return counter
end

return progress
