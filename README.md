# Buffer Serializer {#buffer-serializer}

> Design Stage: In Progress

#### Table of Contents
- [Purpose](#purpose)
- [Requirements](#requirements)
- [Usage Cases](#usage-cases)
- [Example](#example)
- [Constant Amount Supported](#constant-amount-supported)
- [Technical Details](#technical-details)


## Purpose {#purpose}

Compression results are limited to the data format, so it must be optimized prior to any compression (to both save bytes and time).  Buffer Serializer is a first pass compressor for numbers, vectors, booleans, and collections thereof, with the intention to perform as a precursor lossless compression approach that prepares the data for a more thorough compression algorithm.  Lossless compression module like Deflate/zlib serve as the more thorough algorithms suited for a second pass.  Custom types are permitted, and approaches can be added to suit usage cases.

The currently supported types are `nil`, `string`, `boolean`, `buffer`, `number`, `vector`, `table`, and `userdata`.  Where `userdata` is used to point to custom types.

## Requirements {#requirements}
Luau 0.670+

## Usage Cases {#usage-cases}
Storing data in a database, transmitting data to a shared source, preparing the data for masking, encryption, or further compression.

## Example {#example}
```luau
-- Serialize
local data = "Hello World!"
local output = BufferSerialize.serialize(data)

-- Deserialize
local input = BufferSerialize.deserialize(output)

print(`Initial Data: {data}, Final Data: {input}`)
```

## Constant Amount Supported {#constant-amount-supported}
| Type | Amount | Cost |
| ---- | ---- | ---- |
| `string` | 64 | 1 byte |
| `number` | 24 | 1 byte |
| `vector` | 24 | 1 byte |
| `userdata` | 16 | 1 byte |
| ---- | ---- | ---- |
| `string` | 1280 | 2 bytes |
| `number` | 1024 | 2 bytes |
| `vector` | 1024 | 2 bytes |
| `userdata` | 1024 | 2 bytes |


## Technical Details {#technical-details}

All approaches that take more than one byte are specified, alongside how many bytes they may take.

`nil`
- [X] nil [0]: The constant `nil` or unsupported types, such as `function` and `thread`

`boolean`
- [X] truthy [1]: The constant `true`
- [X] falsy [2]: The constant `false`

`buffer`
- [X] empty [3]: The empty buffer
- [X] byte [4]: Represents that a buffer has a length that can be represented as a byte (Takes 2 + bufferLen bytes)
- [X] char [5]: Represents that a buffer has a length that can be represented as a char (Takes 3 + bufferLen bytes)
- [X] three_byte [6]: Represents that a buffer has a length that can be represented in 3 bytes (Takes 4 + bufferLen bytes)
- [X] int [7]: Represents that a buffer has a length that can be represented as an int (Takes 5 + bufferLen bytes)
- [ ] UNKNOWN [8]: An approach that may be used in the future.

`string`
- [X] empty [9]: The constant `""`
- [X] byte [10]: Represents that a string has a length that can be represented as a byte (Takes 2 + strLen bytes)
- [X] char [11]: Represents that a string has a length that can be represented as a char (Takes 3 + strLen bytes)
- [X] three_byte [12]: Represents that a string has a length that can be represented in 3 bytes (Takes 4 + strLen bytes)
- [X] int [13]: Represents that a string has a length that can be represented as an int (Takes 5 + strLen bytes)
- [ ] concatcn [14]: Concatenation of a constant and a number, support of strings up to 32 characters (Takes 3-5 bytes)
- [ ] concatnc [15]: Concatenation of a number and a constant, support of strings up to 32 characters (Takes 3-5 bytes)
- [ ] UNKNOWN [16]: An approach that may be used in the future.
- [ ] UNKNOWN [17]: An approach that may be used in the future.
- [ ] UNKNOWN [18]: An approach that may be used in the future.

`number`
- [X] zero [88]: The constant `0`
- [X] one [89]: The constant `1`
- [X] byte [90]: Represents that the number is a byte (Takes 2 byte)
- [X] char [91]: Represents that the number is a char (2 bytes) (Takes 3 byte)
- [X] three_byte [92]: Represents that the number is 3 bytes (Takes 4 byte)
- [X] int [93]: Represents that the number is an int (4 bytes) (Takes 5 byte)
- [X] float [94]: Represents that the number is a float (4 bytes) (Takes 5 byte)
- [X] double [95]: Represents that the number is a double (8 bytes) (Takes 9 byte)
- [ ] UNKNOWN [96]: An approach that may be used in the future, maybe five_byte.
- [ ] UNKNOWN [97]: An approach that may be used in the future, maybe six_byte.
- [ ] UNKNOWN [98]: An approach that may be used in the future.
- [ ] UNKNOWN [99]: An approach that may be used in the future.

`vector`: (X, Y, Z), All of which are floats.
- [ ] zero [128]: The constant `(0,0,0)`
- [ ] one [129]: The constant `(1,1,1)`
- [ ] x_axis [130]: The constant `(1,0,0)`
- [ ] y_axis [131]: The constant `(0,1,0)`
- [ ] z_axis [132]: The constant `(0,0,1)`
- [ ] xy_axis [133]: The constant `(1,1,0)`
- [ ] xz_axis [134]: The constant `(1,0,1)`
- [ ] yz_axis [135]: The constant `(0,1,1)`
- [ ] byte [136]: Represents that all three values are bytes (Takes ?? byte)
- [ ] char [137]: Represents that all three values are chars (Takes ?? byte)
- [ ] three_byte [138]: Represents that all three values are three_bytes (Takes ?? byte)
- [ ] float [139]: Represents that all three values are floats (Takes ?? byte, worst case)
- [ ] number [140]: Represents that at least one of the values is of a different type (Takes ?? to ?? bytes)
- [ ] scalar_byte [141]: Represents that the vector is a byte multiple of one of the constants (Takes ?? bytes)
- [ ] scalar_char [142]: Represents that the vector is a char multiple of one of the constants (Takes ?? bytes)
- [ ] scalar_three_byte [143]: Represents that the vector is a three_byte multiple of one of the constants (Takes ?? bytes)
- [ ] scalar_float [144]: Represents that the vector is a float multiple of one of the constants (Takes 1+4+1 = 6 bytes)
- [ ] scalar_number [145]: Represents that the vector is a number multiple of one of the constants (Takes ?? bytes)
- [ ] UNKNOWN [145]: An approach that may be used in the future.
- [ ] UNKNOWN [146]: An approach that may be used in the future.
- [ ] UNKNOWN [147]: An approach that may be used in the future.
- [ ] UNKNOWN [148]: An approach that may be used in the future.

`table` [**Subject to change**]
Definition of array used: An array is a list of elements from index 1 to n where there exist no gaps between the integers 1 and n.

- [ ] empty table [178]: The constant ```{}```
- [ ] array_one [179]: Represents an array whose length can be represented in a byte
- [ ] array_two [180]: Represents an array whose length can be represented in a char
- [ ] array_three [181]: Represents an array whose length can be represented in three bytes
- [ ] dict_one [182]: Represents a dictionary whose length can be represented in a byte
- [ ] dict_two [183]: Represents a dictionary whose length can be represented in a char
- [ ] dict_three [184]: Represents a dictionary whose length can be represented in three bytes

The below are ONLY worth it to save space in the buffer by bypassing the array indeces.
- [ ] a1d1 [185]: Represents a mixed table whose array part can be represented using a byte and dictionary part using another byte
- [ ] a1d2 [186]: Represents a mixed table whose array part can be represented using a byte and dictionary part using another char
- [ ] a1d3 [187]: Represents a mixed table whose array part can be represented using a byte and dictionary part using another three bytes
- [ ] a2d1 [188]: Represents a mixed table whose array part can be represented using a char and dictionary part using another byte
- [ ] a2d2 [189]: Represents a mixed table whose array part can be represented using a char and dictionary part using another char
- [ ] a2d3 [190]: Represents a mixed table whose array part can be represented using a char and dictionary part using another three bytes
- [ ] a3d1 [191]: Represents a mixed table whose array part can be represented using three bytes and dictionary part using another byte
- [ ] a3d2 [192]: Represents a mixed table whose array part can be represented using three bytes and dictionary part using another char
- [ ] a3d3 [193]: Represents a mixed table whose array part can be represented using three bytes and dictionary part using another three bytes

Useful to allow for tables to store themselves, avoiding recursive issues.
- [ ] equal_to_parent [194]: Represents that the table is equivalent in reference to the parent table
- [ ] equal_to_existing_table [195]: Two bytes of similar tables
(Do we want to have equal_to_existing_value?  It can be done in the higher compression stage, but if it is fast enough it could be done here.)