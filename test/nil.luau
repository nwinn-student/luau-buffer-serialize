--!strict
-- Runs tests for ../BufferSerializer/nil

local passed = true
local function test(cond: boolean, msg: string)
	if cond then
		return
	end
	passed = false
	print(`[TEST] FAILED: {msg} {debug.traceback("", 2)}`)
end


-- Check that nil.luau works properly
local nilSerialize = require("../src/nil").serialize
local nilDeserialize = require("../src/nil").deserialize

local Sir_Nil = nilSerialize(nil, buffer.create(1), 0, 1)

test(nil == nilDeserialize(Sir_Nil, 0), 
	`nil must be nil (got {nilDeserialize(Sir_Nil, 0)})`)

test(0 == buffer.readu8(Sir_Nil, 0)
		and buffer.len(Sir_Nil) == 1, 
	`nil must be a buffer of length 1 (got {
			buffer.len(Sir_Nil)
		}) and whose first byte is 0 (got {
			buffer.readu8(Sir_Nil, 0)
		})`)


-- Check that init.luau works with nil.luau properly
local serialize = require("../src").serialize
local deserialize = require("../src").deserialize

Sir_Nil = serialize(nil)

test(nil == deserialize(Sir_Nil), 
	`nil must be nil (got {deserialize(Sir_Nil)})`)

test(0 == buffer.readu8(Sir_Nil, 0)
		and buffer.len(Sir_Nil) == 1, 
	`nil must be a buffer of length 1 (got {
			buffer.len(Sir_Nil)
		}) and whose first byte is 0 (got {
			buffer.readu8(Sir_Nil, 0)
		})`)

print(`[TEST] NIL {
		if passed then "PASSED" else "FAILED"
	}`)

return {}
