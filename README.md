# Buffer Serializer

> Design Stage: In Progress

Compression results are limited to the data format, so it must be optimized prior to any compression (to both save bytes and time).  Buffer Serializer is a first pass compressor for numbers, vectors, booleans, and collections thereof, with the intention to perform as a precursor lossless compression approach that prepares the data for a more thorough compression algorithm.  Lossless compression module like Deflate/zlib serve as the more thorough algorithms suited for a second pass.  Custom types are permitted, and approaches can be added to suit usage cases.

The currently supported types are `nil`, `string`, `boolean`, `buffer`, `number`, `vector`, `table`, and `userdata`.  Where `userdata` is used to point to custom types.

# Requirements
Luau 0.670+

# Usage Cases
Storing data in a database, transmitting data to a shared source, preparing the data for masking, encryption, or further compression.

# Example Inputs/Outputs
100 is a byte, so we can say it is numberType, byteApproach, 100.  Which totals 1+1=2 bytes (100 -> '100' is 3 bytes, so we save one).

15.5 is a float, so we can say it is numberType, floatApproach, 15.5.  Which totals 1+4=5 bytes (15.5 -> '15.5' is 4 bytes, so we lose one).

(0,1,5) is a vector, so we can say it is vectorType, byteApproach, 0, 1, 5.  Which totals 1+1+1+1=4 bytes ((0,1,5) -> '(0,1,5)' is 7 bytes, so we save three).

(1.5, 2.5, 0.5) is a vector, so we can say it is vectorType, floatApproach, 1.5, 2.5, 0.5.  Which totals 1+4+4+4=13 bytes ((1.5,2.5,0.5) -> '(1.5,2.5,0.5)' is 13 bytes, so we save none).

# Technical Details
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

`table`
- [ ] empty table [178]: The constant ```{}```
- [ ] array_one [179]: 
- [ ] array_two [180]: 
- [ ] array_three [181]: 
- [ ] dict_1 [182]: 
- [ ] dict_2 [183]: 
- [ ] dict_3 [184]: 
- [ ] a1d1 [185]: 
- [ ] a1d2 [186]: 
- [ ] a1d3 [187]: 
- [ ] a2d1 [188]: 
- [ ] a2d2 [189]: 
- [ ] a2d3 [190]: 
- [ ] a3d1 [191]: 
- [ ] a3d2 [192]: 
- [ ] a3d3 [193]:
- [ ] equal_to_parent [194]:
- [ ] equal_to_nth_ancestor [195]: 
- [ ] equal_to_nth_existing_1 [196]: 
- [ ] equal_to_nth_existing_2 [197]: 
- [ ] array_same_value [198]:  
- [ ] same_value [199]: 


## Byte Specification
 * 0 = nil / function / thread = 1
 * 1-2 = boolean = 2
 * 3-8 = buffer = 6

### String
 * 9-18 = string = 10
 * 19-82 = custom string = 64 (constants)
 * 83-87 = next_string = 5 (entire next byte for string constants)

### Number
 * 88-99 = number = 12
 * 100-123 = custom number = 24 (constants)
 * 124-127 = next_num = 4 (entire next byte is for number constants)

### Vector
 * 128-149 = vector = 22
 * 150-173 = custom vector = 24 (constants)
 * 174-177 = next_vec = 4 (entire next byte is for vector constants)

### Table
 * 178-205 = table = 28

### Userdata
 * 206-211 = userdata = 6 (custom approaches)
 * 212-227 = custom userdata = 16 (constants)
 * 228-231 = next_ud = 4 (entire next byte is for userdata constants)

### Future Approaches (just in case)
 * 232-255 = future = 24

 - Max String Constant Count: 1344
 - Max Number Constant Count: 1048
 - Max Vector Constant Count: 1048
 - Max Userdata Constant Count: 1040
