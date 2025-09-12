--!strict
-- Runs tests for ../BufferSerializer/boolean

local passed = true
local function test(cond: boolean, msg: string)
	if cond then
		return
	end
	passed = false
	print(`[TEST] FAILED: {msg} {debug.traceback("", 2)}`)
end


-- Check that boolean.luau works properly
local booleanSerialize = require("../src/boolean").serialize
local booleanDeserialize = require("../src/boolean").deserialize

local True_Bool = booleanSerialize(true, buffer.create(1), 0, 1)
local False_Bool = booleanSerialize(false, buffer.create(1), 0, 1)

test(true == booleanDeserialize(True_Bool, 0), 
	`true must be true (got {booleanDeserialize(True_Bool, 0)})`)

test(1 == buffer.readu8(True_Bool, 0)
		and buffer.len(True_Bool) == 1, 
	`true must be a buffer of length 1 (got {
			buffer.len(True_Bool)
		}) and whose first byte is 1 (got {
			buffer.readu8(True_Bool, 0)
		})`)

test(false == booleanDeserialize(False_Bool, 0), 
	`false must be false (got {booleanDeserialize(False_Bool, 0)})`)

test(2 == buffer.readu8(False_Bool, 0)
		and buffer.len(False_Bool) == 1, 
	`false must be a buffer of length 2 (got {
			buffer.len(False_Bool)
		}) and whose first byte is 1 (got {
			buffer.readu8(False_Bool, 0)
		})`)


-- Check that init.luau works with buffer.luau properly
local serialize = require("../src").serialize
local deserialize = require("../src").deserialize

True_Bool = serialize(true)
False_Bool = serialize(false)

test(true == deserialize(True_Bool), 
	`true must be true (got {deserialize(True_Bool)})`)

test(1 == buffer.readu8(True_Bool, 0)
		and buffer.len(True_Bool) == 1, 
	`true must be a buffer of length 1 (got {
			buffer.len(True_Bool)
		}) and whose first byte is 1 (got {
			buffer.readu8(True_Bool, 0)
		})`)
		
test(false == deserialize(False_Bool), 
	`false must be false (got {deserialize(False_Bool)})`)

test(2 == buffer.readu8(False_Bool, 0)
		and buffer.len(False_Bool) == 1, 
	`false must be a buffer of length 1 (got {
			buffer.len(False_Bool)
		}) and whose first byte is 2 (got {
			buffer.readu8(False_Bool, 0)
		})`)

print(`[TEST] BOOLEAN {
		if passed then "PASSED" else "FAILED"
	}`)

return {}
