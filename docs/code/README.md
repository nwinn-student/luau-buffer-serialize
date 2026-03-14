**Table of Contents**

- [serialize](#serialize)
- [deserialize](#deserialize)
- [supportUserdata](#supportuserdata)
- [isSupported](#issupported)


## Serialize

**Type**

`(value: any): buffer`

Serializes the provided value into a buffer.

- Follows the specified format in the [spec](../spec/format.md).

**Recommendations:**
- Protect value from concurrent modifications, specifically tables and buffers.

**Example:**
```luau
local BufferSerializer = require("./path/to/BufferSerializer")

local serialData = BufferSerializer.serialize({ "Foo", "Foo" })
```
**Parameters**
- value - the value to serialize

**Returns**
- a buffer representing the serialized value

## Deserialize

**Type**

`(value: buffer): any`

Deserializes the provided buffer, producing the value originally serialized.

- Operates under the assumption that the buffer follows the specified format in
	[spec](../spec/format.md).
- Capable of deserializing values impossible for `serialize` to produce.

**Recommendations:**
- Protect value from concurrent modifications.

**Example:**
```luau
local BufferSerializer = require("./path/to/BufferSerializer")
local serialData = BufferSerializer.serialize({ "Foo", "Foo" })

local originData = BufferSerializer.deserialize(serialData)
```
**Parameters**
- value - buffer containing a serialized value

**Errors**
- Failed to parse buffer
- Failed to parse string
- Failed to parse number
- Failed to parse built-in vector constant
- Failed to parse vector
- Failed to parse table
- Failed to parse existing value
- Failed to parse nil in a dictionary
- Failed to parse future
- Failed to parse extension
- buffer access out of bounds

**Returns**
- the original value

## SupportUserdata

**Type**

```luau
type Support = {
	serialize: (
		value: any,
		buf: buffer,
		pos: number,
		size: number
	) -> (buffer, number, number)?,
	deserialize: (buf: buffer, pos: number) -> (any, number)?,
}
type supportUserdata = (record: Support) -> ()
```

Adds support for a userdata or group of userdata to be
(de)serialized.

**Example**
```luau
local BufferSerializer = require("./path/to/BufferSerializer")
local inflate = require("./path/to/BufferSerializer/inflate")

local sample_userdata = newproxy()

BufferSerializer.supportUserdata({
	serialize = function(value: any, buf: buffer, pos: number, size: number)
		if value ~= sample_userdata then
			return
		end
		buf, size = inflate(buf, pos + 1, size)
		buffer.writeu8(buf, pos, 0)
		return buf, pos + 1, size
	end,
	deserialize = function(buf: buffer, pos: number)
		local id = buffer.readu8(buf, pos)
		if id == 0 then
			return sample_userdata, pos + 1
		end
	end,
})

local serialData = BufferSerializer.serialize(sample_userdata)
```

**Parameters**
- record - the container holding the (de)serialize functions

**Errors**
- expected table
- only "serialize" or "deserialize" can be within record
- record.(de)serialize must be a function

## IsSupported

**Type**

`(ud: any) -> boolean`

Returns whether the userdata is capable of being serialized and deserialized.

- Meaning the userdata does not deserialize into the unsupported userdata constant

**Parameters**
- ud - the userdata to check

**Errors**
- Failed to parse userdata
- Failed to parse custom userdata
- buffer access out of bounds