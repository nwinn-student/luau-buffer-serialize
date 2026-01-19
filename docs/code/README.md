**Table of Contents**

- [serialize](#serialize)
- [deserialize](#deserialize)
- [pair](#pair)


## Serialize

**Type**

`(value: any): buffer`

Serializes the provided value into a buffer.

- Follows the specified format in [FORMAT.md](../FORMAT.md).

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
	[FORMAT.md](../FORMAT.md).
- Capable of deserializing values impossible for `serialize` to produce.

**Recommendations:**
- Protect value from concurrent modifications.

**Example:**
```luau
local BufferSerializer = require("./path/to/BufferSerializer")
local serialData = BufferSerializer.serialize({ "Foo", "Foo" })

local originData = BufferSerializer.deserialize(serialData)
```
** Parameters**
- value - buffer containing a serialized value

**Errors**
- buffer access out of bounds

**Returns**
- the original value



## Pair

**Type**

`(id: number, value: any): ()`

- Ids replace the value when serializing, should the value be rawequal.
	- Only applicable within tables.
	- Initially stored [ID][VALUE], all further instances of the value are
	 stored as [ID].
- Values replace the id when deserializing.
- Equivalent userdata may not be rawequal
	- See [userdata.luau](./userdata.luau) for information about supporting
	 userdata.

- Ids are stored as 1-2 bytes, depending on the number associated with the id
 and the value's type.

| **Type**   | **Id Range**    | **Cost** |
|------------|-----------------|----------|
| `string`   | 1-64            | 1 byte   |
| `number`   | 1-32            | 1 byte   |
| `vector`   | 1-32            | 1 byte   |
| `userdata` | 1-16            | 1 byte   |
|            |                 |          |
| `string`   | 65-1343         | 2 bytes  |
| `number`   | 33-1055         | 2 bytes  |
| `vector`   | 33-1055         | 2 bytes  |
| `userdata` | 16-1039         | 2 bytes  |

**Recommendations:**
- Calculate the word frequency of your dataset to determine which values to link to
 what ids.
- Ensure that linked values cannot be stored for less than or equal to the associated
 id cost (in bytes).
- Spare a range of ids for future additions.
- When concurrently modifying pairs, ensure that an id is not assigned to a different
 value.

**Example:**
```luau
local BufferSerializer = require("./path/to/BufferSerializer")

-- 5 is between 1 and 64, so it will take 1 byte to store the second "Foo"
BufferSerializer.pair(5, "Foo")

local serialData = BufferSerializer.serialize({ "Foo", "Foo" })
```
**Parameters**
- id - the number associated with the value
- value - the value reference compared against when serializing

**Errors**
- Invalid type: When the value is not a string, number, vector, or userdata
- Invalid id: When the id is not an integer
- Invalid id: When the id is not between 1 and N, where N depends on the value's type
- Invalid value: When the value is NaN
- Invalid number: When the value is 0 or 1
- Invalid string: When the value is ""
- Invalid vector: When the value is a built-in vector constant

