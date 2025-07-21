# Buffer Serializer

> Design Stage: In Progress

#### Table of Contents
- [Purpose](#purpose)
- [Requirements](#requirements)
- [Usage Cases](#usage-cases)
- [Example](#example)
- [Constant Amount Supported](#constant-amount-supported)
- [Technical Details](#technical-details)


## Purpose

BufferSerializer is a serializer for complex data structures with the capability to compress known constants whose goal tredges the line of speed and effective output size.  
  
The currently supported types are `nil`, `string`, `boolean`, `buffer`, `number`, `vector`, `table`, and `userdata`.

## Requirements
[Luau 0.670+](https://github.com/luau-lang/luau/releases)

## Usage Cases
A user may need to prepare data for storing in a database, they will use BufferSerializer to convert the table with the data into a buffer, then passing the buffer to a lossless compressor module such as [LibDeflate](https://github.com/safeteeWow/LibDeflate) and storing the value.

Another user may need to pass data from one server to another, they will use BufferSerializer to convert the data into a buffer, then a string, passing the Luau string to the other server to be deserialized and understood.

Another user may need to serialize a table that contains itself, as they wish to pass classes and objects across the network.  BufferSerializer can be used to convert the table into a buffer, which is then converted into a string and passed across the network.

A user with an extension of Luau may wish to have their userdata objects specially handled, using BufferSerializer, they create a function to handle userdata objects that are not constants and use BufferSerializer to convert the userdata's information into understandable information.  When reading the information, another specified function is called to specially read the userdata.


## Example
```luau
-- Serialize
local data = "Hello World!"
local output = BufferSerialize.serialize(data)

-- Deserialize
local input = BufferSerialize.deserialize(output)

print(`Initial Data: {data}, Final Data: {input}`)
```

## Constant Amount Supported
| **Type** | **Amount** | **Cost** |
| ---- | ---- | ---- |
| `string` | 64 | 1 byte |
| `number` | 24 | 1 byte |
| `vector` | 24 | 1 byte |
| `userdata` | 16 | 1 byte |
|  |  |  |
| `string` | 1280 | 2 bytes |
| `number` | 1024 | 2 bytes |
| `vector` | 1024 | 2 bytes |
| `userdata` | 1024 | 2 bytes |


## Technical Details

All approaches that take more than one byte are specified, alongside how many bytes they may take.

`nil`
- [X] nil [0]: The constant `nil` or unsupported types, such as `function` and `thread`

`boolean`
- [X] truthy [1]: The constant `true`
- [X] falsy [2]: The constant `false`

`buffer`
- [X] empty [3]: The empty buffer
- [X] byte [4]: A buffer has a length that can be represented as a byte (Takes 2 + bufferLen bytes)
- [X] char [5]: A buffer has a length that can be represented as a char (Takes 3 + bufferLen bytes)
- [X] three_byte [6]: A buffer has a length that can be represented in 3 bytes (Takes 4 + bufferLen bytes)
- [X] int [7]: A buffer has a length that can be represented as an int (Takes 5 + bufferLen bytes)
- [ ] UNKNOWN [8]: An approach that may be used in the future.

`string`
- [X] empty [9]: The constant `""`
- [X] byte [10]: A string has a length that can be represented as a byte (Takes 2 + strLen bytes)
- [X] char [11]: A string has a length that can be represented as a char (Takes 3 + strLen bytes)
- [X] three_byte [12]: A string has a length that can be represented in 3 bytes (Takes 4 + strLen bytes)
- [X] int [13]: A string has a length that can be represented as an int (Takes 5 + strLen bytes)
- [ ] concatcn [14]: Concatenation of a constant and a number (Takes 3-5 bytes, 32- chars)
- [ ] concatnc [15]: Concatenation of a number and a constant (Takes 3-5 bytes, 32- chars)
- [ ] UNKNOWN [16]: An approach that may be used in the future.
- [ ] UNKNOWN [17]: An approach that may be used in the future.
- [ ] UNKNOWN [18]: An approach that may be used in the future.

`number`
- [X] zero [88]: The constant `0`
- [X] one [89]: The constant `1`
- [X] byte [90]: The number is a byte (Takes 2 byte)
- [X] char [91]: The number is a char (2 bytes) (Takes 3 byte)
- [X] three_byte [92]: The number is 3 bytes (Takes 4 byte)
- [X] int [93]: The number is an int (4 bytes) (Takes 5 byte)
- [X] float [94]: The number is a float (4 bytes) (Takes 5 byte)
- [X] double [95]: The number is a double (8 bytes) (Takes 9 byte)
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
- [ ] byte [136]: All three values are bytes (Takes 4 bytes)
- [ ] char [137]: All three values are chars (Takes 4 to 7 bytes)
- [ ] three_byte [138]: All three values are three_bytes (Takes 4 to 10 bytes)
- [ ] float [139]: All three values are floats (Takes 4 to 13 bytes, worst case) 
- [ ] number [140]: At least one of the values is of a different type (Takes 4 to 15 bytes) 
- [ ] scalar_byte [141]: The vector is a byte multiple of one of the constants (Takes 3 bytes)
- [ ] scalar_char [142]: The vector is a char multiple of one of the constants (Takes 4 bytes)
- [ ] scalar_three_byte [143]: The vector is a three_byte multiple of one of the constants (Takes 5 bytes)
- [ ] scalar_float [144]: The vector is a float multiple of one of the constants (Takes 6 bytes)
- [ ] scalar_number [145]: The vector is a number multiple of one of the constants where the number is also a constant (Takes 3 to 4 bytes)
- [ ] UNKNOWN [145]: An approach that may be used in the future.
- [ ] UNKNOWN [146]: An approach that may be used in the future.
- [ ] UNKNOWN [147]: An approach that may be used in the future.
- [ ] UNKNOWN [148]: An approach that may be used in the future.

`table` [**Subject to change**]  
Definition of array used: An array is a list of elements from index 1 to n where there exist no gaps between the integers 1 and n.  
The arraySize variable represents the amount of bytes used to store all of the values within the array part.  The minimum value for arraySize is arrayLen, but such an occurance is highly unlikely.  
The dictSize variable represents the amount of bytes used to store all of the keys and values within the dictionary part.  The minimum value for dictSize is dictLen * 2, but such an occurance is highly unlikely.

- [ ] empty table [178]: The constant ```{}```
- [ ] array_one [179]: An array whose length can be represented in a byte (Takes 2 + arraySize bytes)
- [ ] array_two [180]: An array whose length can be represented in a char (Takes 3 + arraySize bytes)
- [ ] array_three [181]: An array whose length can be represented in three bytes (Takes 4 + arraySize bytes)
- [ ] dict_one [182]: A dictionary whose length can be represented in a byte (Takes 2 + dictSize bytes)
- [ ] dict_two [183]: A dictionary whose length can be represented in a char (Takes 3 + dictSize bytes)
- [ ] dict_three [184]: A dictionary whose length can be represented in three bytes (Takes 4 + dictSize bytes)

The below are ONLY worth it to save space in the buffer by bypassing the array indeces.
- [ ] a1d1 [185]: A mixed table whose array part can be represented using a byte and dictionary part using another byte (Takes 3 + arraySize + dictSize bytes)
- [ ] a1d2 [186]: A mixed table whose array part can be represented using a byte and dictionary part using another char (Takes 4 + arraySize + dictSize bytes)
- [ ] a1d3 [187]: A mixed table whose array part can be represented using a byte and dictionary part using another three bytes (Takes 5 + arraySize + dictSize bytes)
- [ ] a2d1 [188]: A mixed table whose array part can be represented using a char and dictionary part using another byte (Takes 4 + arraySize + dictSize bytes)
- [ ] a2d2 [189]: A mixed table whose array part can be represented using a char and dictionary part using another char (Takes 5 + arraySize + dictSize bytes)
- [ ] a2d3 [190]: A mixed table whose array part can be represented using a char and dictionary part using another three bytes (Takes 6 + arraySize + dictSize bytes)
- [ ] a3d1 [191]: A mixed table whose array part can be represented using three bytes and dictionary part using another byte (Takes 5 + arraySize + dictSize bytes)
- [ ] a3d2 [192]: A mixed table whose array part can be represented using three bytes and dictionary part using another char (Takes 6 + arraySize + dictSize bytes)
- [ ] a3d3 [193]: A mixed table whose array part can be represented using three bytes and dictionary part using another three bytes (Takes 7 + arraySize + dictSize bytes)

Useful to allow for tables to store themselves.
- [ ] equal_to_parent [194]: The table is equivalent in reference to the parent table

Useful to deduplicate.
- [ ] equal_to_existing_value [195]: Two bytes of similar values (Takes 3 bytes)
- [ ] UNKNOWN [196]: An approach that may be used in the future.
- [ ] UNKNOWN [197]: An approach that may be used in the future.
- [ ] UNKNOWN [198]: An approach that may be used in the future.
- [ ] UNKNOWN [199]: An approach that may be used in the future.
- [ ] UNKNOWN [200]: An approach that may be used in the future.
- [ ] UNKNOWN [201]: An approach that may be used in the future.
- [ ] UNKNOWN [202]: An approach that may be used in the future.
- [ ] UNKNOWN [203]: An approach that may be used in the future.
- [ ] UNKNOWN [204]: An approach that may be used in the future.
- [ ] UNKNOWN [205]: An approach that may be used in the future.