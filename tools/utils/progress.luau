local progress = {}

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
		print("\r\b\r\b\r\b\r") -- resets to start
		print(display .. (" "):rep(43 - #display))

		local bar = (">"):rep((counter.completed / totalTasks) * 34 // 1)
		bar ..= (" "):rep(34 - #bar)

		local duration = (100 * (os.clock() - startTime) // 1) / 100

		print(`{bar} | {duration} s`)
	end
	function counter:complete(msg: string)
		counter.completed += 1

		if counter.completed == totalTasks then
			print("\r\b\r\b\r\b\r") -- resets to start
			-- fill old with spaces
			print((" "):rep(45) .. "\n" .. (" "):rep(45))
			print("\r\b\r\b\r\b\r")
			display = nil
		end
	end

	return counter
end

return progress
