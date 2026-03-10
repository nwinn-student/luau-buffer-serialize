**Table of Contents**

- [serialize](#serialize)
- [deserialize](#deserialize)


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
