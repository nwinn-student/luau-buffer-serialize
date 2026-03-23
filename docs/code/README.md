**API Reference**

- [serialize](#serialize): Serializes the provided value into a buffer
- [deserialize](#deserialize): Produces the value originally serialized
- [supportUserdata](#supportuserdata): Allows for custom userdata (de)serialized
- [isSupported](#issupported): Whether the userdata is capable of being (de)serialized


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
type UserdataSupport = {
    serialize = (
        value: any,
        buf: buffer,
        pos: number,
        size: number
    ) -> (buffer, number, number),
    deserialize = (buf: buffer, pos: number) -> (any, number),
}

type supportUserdata = (record: UserdataSupport) -> ()
```

Adds support for a userdata or group of userdata to be
(de)serialized.

- The provided functions will be called on a last to first supported basis.
- Duplicate support functions will be shifted to the front.

**Recommendations:**
- Group userdata supported by the same environment/runtime together.
- Consider that later supported functions may attempt to handle the
 supported userdata, which may be undesirable since they are called **first**.
  - If undesirable, privatize `BufferSerializer` and provide a public wrapper that 
   replaces `bs.supportUserdata` with:
  ```luau
  local function supportUserdata(record: bs.UserdataSupport): ()
    bs.supportUserdata(record)
    -- main_record is defined earlier and **must** run first
    bs.supportUserdata(main_record)
  end
  ```
- Provide and read documentation surrounding the supported userdata.
  - Conflicting bytecode or opcodes will either corrupt data or cause errors.
  - Removing or modifying support can also corrupt data or cause errors.

**Example**
```luau
local BufferSerializer = require("@BufferSerializer")

local sample_userdata = newproxy()
local sample_id = 0

BufferSerializer.supportUserdata({
	serialize = function(value: any, buf: buffer, pos: number, size: number)
		if value ~= sample_userdata then
			return buf, pos, size
		end
		buffer.writeu8(buf, pos, sample_id)
		return buf, pos + 1, size
	end,
	deserialize = function(buf: buffer, pos: number)
		local id = buffer.readu8(buf, pos)
		if id == sample_id then
			return sample_userdata, pos + 1
		end
		return nil, pos
	end,
})

local serialData = BufferSerializer.serialize(sample_userdata)
```

**Parameters**
- record - the container holding the (de)serialize functions

**Errors**
- Invalid type: When record is not a table
- Incomplete record: When record is missing (de)serialize
- Invalid property: When the property isn't (de)serialize
- Invalid property type: When (de)serialize isn't a function

## IsSupported

**Type**

`(ud: any) -> boolean`

Returns whether the userdata is capable of being serialized and deserialized.

- Meaning the userdata does not deserialize into the unsupported userdata constant.

**Recommendations:**
- Ensure the userdata deserializes into the desired form.

**Parameters**
- ud - the userdata to check

**Errors**
- Failed to parse userdata
- Failed to parse custom userdata
- buffer access out of bounds