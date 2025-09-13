--!strict
-- Runs tests for ../BufferSerializer/buffer

local passed = true
local function test(cond: boolean, msg: string)
	if cond then
		return
	end
	passed = false
	print(`[TEST] FAILED: {msg} {debug.traceback("", 2)}`)
end

local bufCre = buffer.create

-- Check that nil.luau works properly (we are not trimming!)
local bufSerialize = require("../src/buffer").serialize
local bufDeserialize = require("../src/buffer").deserialize

local Sir_Empty = bufSerialize(bufCre(0), bufCre(1), 0, 1)
local Sir_Byte = bufSerialize(bufCre(2^0), bufCre(1), 0, 1)
local Sir_Char = bufSerialize(bufCre(2^8), bufCre(1), 0, 1)
local Sir_Tryte = bufSerialize(bufCre(2^16), bufCre(1), 0, 1)
local Sir_Int = bufSerialize(bufCre(2^24), bufCre(1), 0, 1)

-- serialization
test(3 == buffer.readu8(Sir_Empty, 0)
		and buffer.len(Sir_Empty) == 1, 
	`empty buffer must be a buffer of length 1 (got {
			buffer.len(Sir_Empty)
		}) and whose first byte is 3 (got {
			buffer.readu8(Sir_Empty, 0)
		})`)
test(4 == buffer.readu8(Sir_Byte, 0)
		and buffer.len(Sir_Byte) == 4, 
	`byte buffer must be a buffer of length 4 (got {
			buffer.len(Sir_Byte)
		}) and whose first byte is 4 (got {
			buffer.readu8(Sir_Byte, 0)
		})`)
test(5 == buffer.readu8(Sir_Char, 0)
		and buffer.len(Sir_Char) == 512, 
	`char buffer must be a buffer of length 512 (got {
			buffer.len(Sir_Char)
		}) and whose first byte is 5 (got {
			buffer.readu8(Sir_Char, 0)
		})`)
test(6 == buffer.readu8(Sir_Tryte, 0)
		and buffer.len(Sir_Tryte) == 131072, 
	`tryte buffer must be a buffer of length 131072 (got {
			buffer.len(Sir_Tryte)
		}) and whose first byte is 6 (got {
			buffer.readu8(Sir_Tryte, 0)
		})`)
test(7 == buffer.readu8(Sir_Int, 0)
		and buffer.len(Sir_Int) == 33554432, 
	`int buffer must be a buffer of length 33554432 (got {
			buffer.len(Sir_Int)
		}) and whose first byte is 7 (got {
			buffer.readu8(Sir_Int, 0)
		})`)

-- deserialization
test(buffer.len(bufDeserialize(Sir_Empty, 0)) == 0,
	`empty buffer must be empty (got {
		buffer.len(bufDeserialize(Sir_Empty, 0))
	})`)
test(buffer.len(bufDeserialize(Sir_Byte, 0)) == 1,
	`byte buffer must be 1 (got {
		buffer.len(bufDeserialize(Sir_Byte, 0))
	})`)
test(buffer.len(bufDeserialize(Sir_Char, 0)) == 256,
	`char buffer must be 256 (got {
		buffer.len(bufDeserialize(Sir_Char, 0))
	})`)
test(buffer.len(bufDeserialize(Sir_Tryte, 0)) == 65536,
	`tryte buffer must be 65536 (got {
		buffer.len(bufDeserialize(Sir_Tryte, 0))
	})`)
test(buffer.len(bufDeserialize(Sir_Int, 0)) == 16777216,
	`int buffer must be 16777216 (got {
		buffer.len(bufDeserialize(Sir_Int, 0))
	})`)


-- Check that init.luau works with buffer.luau properly
local serialize = require("../src").serialize
local deserialize = require("../src").deserialize

Sir_Empty = serialize(bufCre(0), bufCre(1), 0, 1)
Sir_Byte = serialize(bufCre(2^0), bufCre(1), 0, 1)
Sir_Char = serialize(bufCre(2^8), bufCre(1), 0, 1)
Sir_Tryte = serialize(bufCre(2^16), bufCre(1), 0, 1)
Sir_Int = serialize(bufCre(2^24), bufCre(1), 0, 1)

-- serialization
test(3 == buffer.readu8(Sir_Empty, 0)
		and buffer.len(Sir_Empty) == 1, 
	`empty buffer must be a buffer of length 1 (got {
			buffer.len(Sir_Empty)
		}) and whose first byte is 3 (got {
			buffer.readu8(Sir_Empty, 0)
		})`)
test(4 == buffer.readu8(Sir_Byte, 0)
		and buffer.len(Sir_Byte) == 3, 
	`byte buffer must be a buffer of length 3 (got {
			buffer.len(Sir_Byte)
		}) and whose first byte is 4 (got {
			buffer.readu8(Sir_Byte, 0)
		})`)
test(5 == buffer.readu8(Sir_Char, 0)
		and buffer.len(Sir_Char) == 259, 
	`char buffer must be a buffer of length 259 (got {
			buffer.len(Sir_Char)
		}) and whose first byte is 5 (got {
			buffer.readu8(Sir_Char, 0)
		})`)
test(6 == buffer.readu8(Sir_Tryte, 0)
		and buffer.len(Sir_Tryte) == 65540, 
	`tryte buffer must be a buffer of length 65540 (got {
			buffer.len(Sir_Tryte)
		}) and whose first byte is 6 (got {
			buffer.readu8(Sir_Tryte, 0)
		})`)
test(7 == buffer.readu8(Sir_Int, 0)
		and buffer.len(Sir_Int) == 16777221, 
	`int buffer must be a buffer of length 16777221 (got {
			buffer.len(Sir_Int)
		}) and whose first byte is 7 (got {
			buffer.readu8(Sir_Int, 0)
		})`)

-- deserialization
test(buffer.len(deserialize(Sir_Empty)) == 0,
	`empty buffer must be empty (got {
		buffer.len(deserialize(Sir_Empty))
	})`)
test(buffer.len(deserialize(Sir_Byte)) == 1,
	`byte buffer must be 1 (got {
		buffer.len(deserialize(Sir_Byte, 0))
	})`)
test(buffer.len(deserialize(Sir_Char)) == 256,
	`char buffer must be 256 (got {
		buffer.len(deserialize(Sir_Char))
	})`)
test(buffer.len(deserialize(Sir_Tryte)) == 65536,
	`tryte buffer must be 65536 (got {
		buffer.len(deserialize(Sir_Tryte))
	})`)
test(buffer.len(deserialize(Sir_Int)) == 16777216,
	`int buffer must be 16777216 (got {
		buffer.len(deserialize(Sir_Int))
	})`)


print(`[TEST] BUFFER {
		if passed then "PASSED" else "FAILED"
	}`)

return {}
