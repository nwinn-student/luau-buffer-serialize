### Supported Types

`nil`, `boolean`, `buffer`, `string`, `number`, `vector`, `table`, `userdata`

All other types are to be treated as `nil`.

### FAQ

**How are numbers stored?  Big-endian or little-endian.**

Numbers are stored in little-endian.

**Are strings compressed?**

No, strings and buffers are stored in their raw form, as sequences of bytes.

**What constitutes an array?**

An array is a list of elements from index 1 to n where there exist no gaps
 between the indeces 1 and n when incrementing the index by 1.

**What are vectors?**

Vectors are immutable storage mediums for three 32-bit floating point numbers
 `(x,y,z)`.

**How are cyclic tables stored?**

Values are recorded and any duplicate is fast pathed to avoid re-serializing and is compressed to 3 bytes (`196`).  Tables are recorded before serializing, so cyclic tables are stored as 3 byte references to prior serialized or currently serializing tables.

**How can I find the size of a table?**

The table size is not stored by default, see [extension support](../extension.md).

**How are paired ids stored?**

Paired ids are stored either in the byte itself, or as a 2 byte number.
 For the 2 byte number, the first byte represents which batch to enter, 
 and the second byte represents the id linked to the value.

**Why are vectors stored in different formats?**

Vectors have multiple modes: scalar multiple, multi-set (byte, char, tryte), and set.  Scalar multiple vectors are multiples of the constant vectors, thus they can be stored in less bytes.  The intent behind multiple modes is primarily to produce smaller output sizes.  Vectors are basically numerical arrays of size 3, so two common cases (multi-set and set) were chosen to account for all cases and then special cases (scalar multiple) get a fast path with little cost.

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
| 8       | 1        | `string`   | The constant `""`                       |
| 9       | 2 + size | `string`   | A string with size < 2^8                |
| 10      | 3 + size | `string`   | A string with size < 2^16               |
| 11      | 4 + size | `string`   | A string with size < 2^24               |
| 12      | 5 + size | `string`   | A string with size < 2^32               |
| 13      | 2        | `string`   | A string of size 1                      |
| 14      | 3        | `string`   | A string of size 2                      |
| 15      | 4        | `string`   | A string of size 3                      |
| 16      | 5        | `string`   | A string of size 4                      |
| 17      | 6        | `string`   | A string of size 5                      |
| 18      | 7        | `string`   | A string of size 6                      |
| 19      | 8        | `string`   | A string of size 7                      |
| 20      | 9        | `string`   | A string of size 8                      |
| 21      | 10       | `string`   | A string of size 9                      |
| 22      | 11       | `string`   | A string of size 10                     |
| 23      | 12       | `string`   | A string of size 11                     |
| 24      | 13       | `string`   | A string of size 12                     |
| 25      | 14       | `string`   | A string of size 13                     |
| 26      | 15       | `string`   | A string of size 14                     |
| 27      | 16       | `string`   | A string of size 15                     |
| 28-91   | 1        | `string`   | The id for a paired string value        |
| 92-96   | 2        | `string`   | The id for a paired string value        |
| 97      | 1        | `number`   | The constant `0`                        |
| 98      | 1        | `number`   | The constant `1`                        |
| 99      | 2        | `number`   | An integer between -2^7 and 2^7-1       |
| 100     | 3        | `number`   | An integer between -2^15 and 2^15-1     |
| 101     | 4        | `number`   | An integer between -2^23 and 2^23-1     |
| 102     | 5        | `number`   | An integer between -2^31 and 2^31-1     |
| 103     | 5        | `number`   | A 32-bit floating point                 |
| 104     | 9        | `number`   | A 64-bit floating point                 |
| 105     | 1        | `number`   | The constant `NaN` or `0 / 0`           |
| 106-137 | 1        | `number`   | The id for a paired number value        |
| 138-141 | 2        | `number`   | The id for a paired number value        |
| 142     | 1        | `vector`   | The constant `(0,0,0)`                  |
| 143     | 1        | `vector`   | The constant `(1,1,1)`                  |
| 144     | 1        | `vector`   | The constant `(1,0,0)`                  |
| 145     | 1        | `vector`   | The constant `(0,1,0)`                  |
| 146     | 1        | `vector`   | The constant `(0,0,1)`                  |
| 147     | 1        | `vector`   | The constant `(1,1,0)`                  |
| 148     | 1        | `vector`   | The constant `(1,0,1)`                  |
| 149     | 1        | `vector`   | The constant `(0,1,1)`                  |
| 150     | 4        | `vector`   | A vector between -2^7 and 2^7-1 (all)   |
| 151     | 7        | `vector`   | A vector between -2^15 and 2^15-1 (all) |
| 152     | 10       | `vector`   | A vector between -2^23 and 2^23-1 (all) |
| 153     | 13       | `vector`   | A vector with 32-bit floating points    |
| 154     | 4-15     | `vector`   | A vector with different types           |
| 155     | 3-7      | `vector`   | A multiple of a constant vector         |
| 156-157 | 0        | `vector`   | **Unknown**                             |
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
