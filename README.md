# Buffer Serializer

> Design Stage: In Progress

#### Table of Contents
- [Purpose](#purpose)
- [Requirements](#requirements)
- [Usage Cases](#usage-cases)
- [Example](#example)
- [Performance](#performance)
- [Constant Amount Supported](#constant-amount-supported)
- [Technical Details](#technical-details)


## Purpose

BufferSerializer is a general-purpose serializer for complex data structures with the capability to compress known constants whose goal tredges the line of speed and effective output size.
  
The currently supported types are `nil`, `string`, `boolean`, `buffer`, `number`, `vector`, `table`, and `userdata`.  `thread` and `functions` are also supported, but they are immediately converted to `nil`.  They can be used to save output size in array structures with potential gaps `{1, 2, 3, fn, 4, 5}`.  The user must define their own serialization / deserialization approach for `userdata`, examples are provided in [examples](./examples).

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

## Performance

Tests were performed comparing Roblox's JSONEncode/Decode, cipharius's MessagePack, and BufferSerializer.  The test code can be located [here](./bench/compare.luau) and personal results [here](./bench/compare_results.txt).

## Constant Amount Supported
| **Type** | **Amount** | **Cost** |
| ---- | ---- | ---- |
| `string` | 64 | 1 byte |
| `number` | 32 | 1 byte |
| `vector` | 32 | 1 byte |
| `userdata` | 16 | 1 byte |
|  |  |  |
| `string` | 1280 | 2 bytes |
| `number` | 1024 | 2 bytes |
| `vector` | 1024 | 2 bytes |
| `userdata` | 1024 | 2 bytes |


## Technical Details

All approaches that take more than one byte are specified, alongside how many bytes they may take.
Corrupted data will be returned as nil, if the data is in a collection then the aspect will become 0 if in 
vector and nil if in table (so not added).

`nil`
- [X] nil [0]: The constant `nil` or unsupported types, such as `function` and `thread`

`boolean`
- [X] truthy [1]: The constant `true`
- [X] falsy [2]: The constant `false`

`buffer`
- [X] empty [3]: The empty buffer
- [X] byte [4]: A buffer has a length that can be represented as a byte (Takes 2 + bufferLen bytes)
- [X] char [5]: A buffer has a length that can be represented as a char (Takes 3 + bufferLen bytes)
- [X] tryte [6]: A buffer has a length that can be represented in 3 bytes (Takes 4 + bufferLen bytes)
- [X] int [7]: A buffer has a length that can be represented as an int (Takes 5 + bufferLen bytes)
- [ ] UNKNOWN [8]: An approach that may be used in the future.

`string`
- [X] empty [9]: The constant `""`
- [X] byte [10]: A string has a length that can be represented as a byte (Takes 2 + strLen bytes)
- [X] char [11]: A string has a length that can be represented as a char (Takes 3 + strLen bytes)
- [X] tryte [12]: A string has a length that can be represented in 3 bytes (Takes 4 + strLen bytes)
- [X] int [13]: A string has a length that can be represented as an int (Takes 5 + strLen bytes)
- [X] concatsn [14]: Concatenation of a string and a positive integer (Takes 3-5 + n bytes, 32- chars)
- [X] concatns [15]: Concatenation of a positive integer and a string (Takes 3-5 + n bytes, 32- chars)
- [X] num [16]: The string can be converted to a positive integer (Takes 2-6 bytes, 32- chars).
- [ ] UNKNOWN [17]: An approach that may be used in the future.
- [ ] UNKNOWN [18]: An approach that may be used in the future.

`number`
- [X] zero [88]: The constant `0`
- [X] one [89]: The constant `1`
- [X] byte [90]: The number is a byte (Takes 2 byte)
- [X] char [91]: The number is a char (2 bytes) (Takes 3 byte)
- [X] tryte [92]: The number is 3 bytes (Takes 4 byte)
- [X] int [93]: The number is an int (4 bytes) (Takes 5 byte)
- [X] float [94]: The number is a float (4 bytes) (Takes 5 byte)
- [X] double [95]: The number is a double (8 bytes) (Takes 9 byte)
- [X] nan [96]: The constant `nan` or `0/0`.
- [ ] UNKNOWN [97]: An approach that may be used in the future, maybe five_byte.
- [ ] UNKNOWN [98]: An approach that may be used in the future, maybe six_byte.
- [ ] UNKNOWN [99]: An approach that may be used in the future.

`vector`: (X, Y, Z), All of which are floats (vector is immutable!).
- [X] zero [136]: The constant `(0,0,0)`
- [X] one [137]: The constant `(1,1,1)`
- [X] x_axis [138]: The constant `(1,0,0)`
- [X] y_axis [139]: The constant `(0,1,0)`
- [X] z_axis [140]: The constant `(0,0,1)`
- [X] xy_axis [141]: The constant `(1,1,0)`
- [X] xz_axis [142]: The constant `(1,0,1)`
- [X] yz_axis [143]: The constant `(0,1,1)`
- [X] byte [144]: All three values are bytes (Takes 4 bytes)
- [X] char [145]: All three values are chars (Takes 7 bytes)
- [X] tryte [146]: All three values are three_bytes (Takes 10 bytes)
- [X] float [147]: All three values are floats (Takes 13 bytes, worst case) 
- [X] number [148]: At least one of the values is of a different type (Takes 4 to 15 bytes) 
- [X] scalar_number [149]: The vector is a multiple of an above constant vector (Takes 3 to 7 bytes)
- [ ] UNKNOWN [150]: An approach that may be used in the future.
- [ ] UNKNOWN [151]: An approach that may be used in the future.
- [ ] UNKNOWN [152]: An approach that may be used in the future.
- [ ] UNKNOWN [153]: An approach that may be used in the future.
- [ ] UNKNOWN [154]: An approach that may be used in the future.
- [ ] UNKNOWN [155]: An approach that may be used in the future.
- [ ] UNKNOWN [156]: An approach that may be used in the future.
- [ ] UNKNOWN [157]: An approach that may be used in the future.

`table`  
Definition of array used: An array is a list of elements from index 1 to n where there exist no gaps between the integers 1 and n.  
The arraySize variable represents the amount of bytes used to store all of the values within the array part.  The minimum value for arraySize is arrayLen, but such an occurance is highly unlikely.  
The dictSize variable represents the amount of bytes used to store all of the keys and values within the dictionary part.  The minimum value for dictSize is dictLen * 2, but such an occurance is highly unlikely.

- [X] empty table [194]: The constant ```{}```
- [X] table [195]: A mixed table that contains both arrayend and tableend to terminate. (Takes 3 + arraySize + dictSize bytes)
- [X] equal_to_existing_value [196]: Two bytes of unique values (Takes 3 bytes)
- [X] array [197]: An array that uses tableend to terminate (Takes 2 + arraySize bytes)
- [X] dict [198]: A dictionary that uses tableend to terminate (Takes 2 + dictSize bytes) 
- [X] arrayend [199]: Used to terminate the array portion of a table
- [X] tableend [200]: Used to terminate a table
- [ ] existing_cache [201]: One byte of unique values, cleared every 256 unique values (Takes 2 bytes).

`userdata`
- [X] custom [202]: A user-defined function is used to read/write the information associated with the userdata (Takes 1+custom bytes)
- [ ] UNKNOWN [203]: An approach that may be used in the future.