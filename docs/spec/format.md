<!--

TODO: Should be similar to FORMAT.md

-->

**Under construction..**

### Supported Types

`nil`, `boolean`, `buffer`, `string`, `number`, `vector`, `table`, `userdata`

All other types are to be treated as `nil`.

### FAQ

**How are numbers stored?  Big-endian or little-endian.**

Numbers are stored in little-endian.

**Are strings compressed?**

No, strings and buffers are stored in their raw form.

**How can I find the size of a table?**

The table size is not stored by default, see [extension support](../extension.md).

**How are paired ids stored?**

Paired ids are stored either in the byte itself, or as a 2 byte number.
 For the 2 byte number, the first byte represents which batch to enter, 
 and the second byte represents the id linked to the value.

## Design

| Tag(s)  | Cost     | Type      | Description                             |
|---------|----------|-----------|-----------------------------------------|
| 0       | 1        | `nil`     | The constant `nil` or unsupported types |
| 1       | 1        | `boolean` | The constant `true`                     |
| 2       | 1        | `boolean` | The constant `false`                    |
| 3       | 1        | `buffer`  | An empty buffer                         |
| 4       | 2 + size | `buffer`  | A buffer with size < 2^8                |
| 5       | 3 + size | `buffer`  | A buffer with size < 2^16               |
| 6       | 4 + size | `buffer`  | A buffer with size < 2^24               |
| 7       | 5 + size | `buffer`  | A buffer with size < 2^32               |
| 8       | 0        | `buffer`  | **Unknown**                             |
| 9       | 1        | `string`  | The constant `""`                       |
| 10      | 2 + size | `string`  | A string with size < 2^8                |
| 11      | 3 + size | `string`  | A string with size < 2^16               |
| 12      | 4 + size | `string`  | A string with size < 2^24               |
| 13      | 5 + size | `string`  | A string with size < 2^32               |
| 14-18   | 0        | `string`  | **Unknown**                             |
| 19-82   | 1        | `string`  | The id for a paired string value        |
| 83-87   | 2        | `string`  | The id for a paired string value        |
| 88      | 1        | `number`  | The constant `0`                        |
| 89      | 1        | `number`  | The constant `1`                        |
| 90      | 2        | `number`  | An integer between -2^7 and 2^7-1       |
| 91      | 3        | `number`  | An integer between -2^15 and 2^15-1     |
| 92      | 4        | `number`  | An integer between -2^23 and 2^23-1     |
| 93      | 5        | `number`  | An integer between -2^31 and 2^31-1     |
| 94      | 5        | `number`  | A 32-bit floating point                 |
| 95      | 9        | `number`  | A 64-bit floating point                 |
| 96      | 1        | `number`  | The constant `NaN` or `0 / 0`           |
| 97-99   | 0        | `number`  | **Unknown**                             |
| 100-131 | 1        | `number`  | The id for a paired number value        |
| 132-135 | 2        | `number`  | The id for a paired number value        |
