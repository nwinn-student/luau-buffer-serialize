<!--

Needs alot of work, can pull from other prs

-->

`serialize(data: any): buffer`: Takes in a value and spits out the serialized
version within a buffer.

`deserialize(data: buffer): any`: Takes in a serialized version of some data
and **recreates** and returns the original data.

## BufferSerializer.pair

**Type**

`(id: number, data: any): ()`

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

