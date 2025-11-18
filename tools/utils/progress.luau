local progress = {}

local stdio = require("@lune/stdio")

function progress.new(totalTasks: number)
	local display = ""
	local counter = {
		completed = 0,
	}

	local startTime = os.clock()
	stdio.write("\n\n")

	function counter:run(msg: string)
		display = "[  Running  ] " .. msg
		stdio.write("\r\b\r\b\r") -- resets to start
		stdio.write(display .. (" "):rep(43 - #display) .. "\n")

		local bar = (">"):rep((counter.completed / totalTasks) * 34 // 1)
		bar ..= (" "):rep(34 - #bar)

		local duration = (100 * (os.clock() - startTime) // 1) / 100

		stdio.write(`{bar} | {duration} s\n`)
	end
	function counter:complete(msg: string)
		counter.completed += 1

		if counter.completed == totalTasks then
			stdio.write("\r\b\r\b\r") -- resets to start
			-- fill old with spaces
			stdio.write((" "):rep(45) .. "\n" .. (" "):rep(45) .. "\n")
			stdio.write("\r\b\r\b\r")
			display = nil
		end
	end

	return counter
end

return progress
