### Supported Types

`nil`, `boolean`, `buffer`, `string`, `number`, `vector`, `table`, `userdata`

All other types are to be treated as `nil`.

### FAQ

**How are numbers stored?  Big-endian or little-endian.**

Numbers are stored in little-endian.

**Are strings compressed?**

No, strings and buffers are stored in their raw form, as sequences of bytes.

**How are cyclic tables stored?**

Values are recorded and any duplicate is fast pathed to avoid re-serializing and is compressed to 3 bytes (`196`).  Tables are recorded before serializing, so cyclic tables are stored as 3 byte references to prior serialized or currently serializing tables.

**How can I find the size of a table?**

The table size is not stored by default, see [extension support](../extension.md).

**How are paired ids stored?**

Paired ids are stored either in the byte itself, or as a 2 byte number.
 For the 2 byte number, the first byte represents which batch to enter, 
 and the second byte represents the id linked to the value.

## Design

| Tag(s)  | Cost     | Type       | Description                             |
|---------|----------|------------|-----------------------------------------|
| 0       | 1        | `nil`      | The constant `nil` or unsupported types |
| 1       | 1        | `boolean`  | The constant `true`                     |
| 2       | 1        | `boolean`  | The constant `false`                    |
| 3       | 1        | `buffer`   | An empty buffer                         |
| 4       | 2 + size | `buffer`   | A buffer with size < 2^8                |
| 5       | 3 + size | `buffer`   | A buffer with size < 2^16               |
| 6       | 4 + size | `buffer`   | A buffer with size < 2^24               |
| 7       | 5 + size | `buffer`   | A buffer with size < 2^32               |
| 8       | 0        | `buffer`   | **Unknown**                             |
| 9       | 1        | `string`   | The constant `""`                       |
| 10      | 2 + size | `string`   | A string with size < 2^8                |
| 11      | 3 + size | `string`   | A string with size < 2^16               |
| 12      | 4 + size | `string`   | A string with size < 2^24               |
| 13      | 5 + size | `string`   | A string with size < 2^32               |
| 14-18   | 0        | `string`   | **Unknown**                             |
| 19-82   | 1        | `string`   | The id for a paired string value        |
| 83-87   | 2        | `string`   | The id for a paired string value        |
| 88      | 1        | `number`   | The constant `0`                        |
| 89      | 1        | `number`   | The constant `1`                        |
| 90      | 2        | `number`   | An integer between -2^7 and 2^7-1       |
| 91      | 3        | `number`   | An integer between -2^15 and 2^15-1     |
| 92      | 4        | `number`   | An integer between -2^23 and 2^23-1     |
| 93      | 5        | `number`   | An integer between -2^31 and 2^31-1     |
| 94      | 5        | `number`   | A 32-bit floating point                 |
| 95      | 9        | `number`   | A 64-bit floating point                 |
| 96      | 1        | `number`   | The constant `NaN` or `0 / 0`           |
| 97-99   | 0        | `number`   | **Unknown**                             |
| 100-131 | 1        | `number`   | The id for a paired number value        |
| 132-135 | 2        | `number`   | The id for a paired number value        |
| 136     | 1        | `vector`   | The constant `(0,0,0)`                  |
| 137     | 1        | `vector`   | The constant `(1,1,1)`                  |
| 138     | 1        | `vector`   | The constant `(1,0,0)`                  |
| 139     | 1        | `vector`   | The constant `(0,1,0)`                  |
| 140     | 1        | `vector`   | The constant `(0,0,1)`                  |
| 141     | 1        | `vector`   | The constant `(1,1,0)`                  |
| 142     | 1        | `vector`   | The constant `(1,0,1)`                  |
| 143     | 1        | `vector`   | The constant `(0,1,1)`                  |
| 144     | 4        | `vector`   | A vector between -2^7 and 2^7-1 (all)   |
| 145     | 7        | `vector`   | A vector between -2^15 and 2^15-1 (all) |
| 146     | 10       | `vector`   | A vector between -2^23 and 2^23-1 (all) |
| 147     | 13       | `vector`   | A vector with 32-bit floating points    |
| 148     | 4-15     | `vector`   | A vector with different types           |
| 149     | 3-7      | `vector`   | A multiple of a constant vector         |
| 150-157 | 0        | `vector`   | **Unknown**                             |
| 158-189 | 1        | `vector`   | The id for a paired vector value        |
| 190-193 | 2        | `vector`   | The id for a paired vector value        |
| 194     | 1        | `table`    | The constant `{}`                       |
| 195     | 3 + size | `table`    | A mixed table                           |
| 196     | 3        | `table`    | Duplicate value                         |
| 197     | 2 + size | `table`    | An array                                |
| 198     | 2 + size | `table`    | A dictionary                            |
| 199     | 1        | `table`    | Array section terminator                |
| 200     | 1        | `table`    | Table terminator                        |
| 201     | 1        | `table`    | **Unknown**                             |
| 202     | 1 + size | `userdata` | Custom userdata                         |
| 203     | 1        | `userdata` | The value `newproxy()`                  |
| 204-213 | 1        | `userdata` | The id for a paired userdata value      |
| 214-215 | 2        | `userdata` | The id for a paired userdata value      |
| 216-239 | 0        | `future`   | Reserved for new types or expansions    |
| 240-255 | 0        | `extend`   | Reserved for extenders                  |
