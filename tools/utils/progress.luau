local progress = {}

local stdio = require("@lune/stdio")
local task = require("@lune/task")

function progress.new(totalTasks: number)
	local display = ""
	local counter = {
		completed = 0,
	}
	function counter:run(msg: string)
		display = "[  Running  ] " .. msg
	end
	function counter:complete(msg: string)
		counter.completed += 1
	end

	-- flawed, for some reason does not do the right thing :<
	-- it yields and doesnot show progress
	task.spawn(function()
		local startTime = os.clock()
		stdio.write("\n\n")
		repeat
			task.wait(1 / 5)

			stdio.write("\r\b\r\b\r") -- resets to start
			stdio.write(display .. (" "):rep(43 - #display) .. "\n")

			local bar = (">"):rep((counter.completed / totalTasks) * 34 // 1)
			bar ..= (" "):rep(34 - #bar)

			local duration = (100 * (os.clock() - startTime) // 1) / 100

			stdio.write(`{bar} | {duration} s\n`)
		until counter.completed == totalTasks

		stdio.write("\r\b\r\b\r") -- resets to start
		-- fill old with spaces
		stdio.write((" "):rep(45) .. "\n" .. (" "):rep(45) .. "\n")
		stdio.write("\r\b\r\b\r")
		display = nil
	end)

	return counter
end

return progress
