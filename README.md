# Buffer Serializer

> Design Stage: In Progress

Compression results are limited to the data format, so it must be optimized prior to any compression (to both save bytes and time).  Buffer Serializer is a first pass compressor for numbers, vectors, booleans, and collections thereof, with the intention to perform as a precursor lossless compression approach that prepares the data for a more thorough compression algorithm.  Lossless compression module like Deflate/zlib serve as the more thorough algorithms suited for a second pass.  Custom types are permitted, and approaches can be added to suit usage cases.

There are 8 types that can be defined and 32 approaches for each type.  An approach can be a type, but it is usually a constant or it defines how to serialize the data.  The currently added types are `string`, `boolean`, `number`, `vector`, `table`, and `userdata`.  Where `userdata` is used to point to custom types.  The two leftover slots can be used to define more custom types, but it will require manually modifying the modules.

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
`boolean`
- [X] truthy: The constant `true` (Takes 1 byte)
- [X] falsy: The constant `false` (Takes 1 byte)

`number`
- [X] zero: The constant `0` (Takes 1 byte)
- [X] one: The constant `1` (Takes 1 byte)
- [X] byte: Represents that the number is a byte (Takes 2 byte)
- [X] char: Represents that the number is a char (2 bytes) (Takes 3 byte)
- [X] three_byte: Represents that the number is 3 bytes (Takes 4 byte)
- [X] int: Represents that the number is an int (4 bytes) (Takes 5 byte)
- [X] float: Represents that the number is a float (4 bytes) (Takes 5 byte)
- [X] double: Represents that the number is a double (8 bytes) (Takes 9 byte)

`vector`: (X, Y, Z), All of which are floats.
 - [X] zero: The constant `(0,0,0)` (Takes 1 byte)
 - [X] one: The constant `(1,1,1)` (Takes 1 byte)
 - [X] x_axis: The constant `(1,0,0)` (Takes 1 byte)
 - [X] y_axis: The constant `(0,1,0)` (Takes 1 byte)
 - [X] z_axis: The constant `(0,0,1)` (Takes 1 byte)
 - [X] xy_axis: The constant `(1,1,0)` (Takes 1 byte)
 - [X] yz_axis: The constant `(0,1,1)` (Takes 1 byte)
 - [X] xz_axis: The constant `(1,0,1)` (Takes 1 byte)
 - [X] byte: Represents that all three values are bytes (Takes 4 byte)
 - [X] char: Represents that all three values are chars (Takes 7 byte)
 - [X] three_byte: Represents that all three values are three_bytes (Takes 10 byte)
 - [X] float: Represents that all three values are floats (Takes 13 byte, worst case)
 - [X] number: Represents that at least one of the values is of a different type (Takes 1+1+1+2 = 5 to 1+5+5+4 = 15 bytes)
 - [X] scalar_byte: Represents that the vector is a byte multiple of one of the constants (Takes 1+1+1 = 3 bytes)
 - [X] scalar_char: Represents that the vector is a char multiple of one of the constants (Takes 1+2+1 = 4 bytes)
 - [X] scalar_three_byte: Represents that the vector is a three_byte multiple of one of the constants (Takes 1+3+1 = 5 bytes)
 - [X] scalar_float: Represents that the vector is a float multiple of one of the constants (Takes 1+4+1 = 6 bytes)

```luau
-- Used for string and table since they have variable sizes
size = 0.625 + math.log(n, 2) / 8
```

`string`
 - [ ] empty: The constant `""` (Takes 1 byte)

`table`
 - [ ] empty table: The constant ```{}``` (Takes 1 byte)

## Byte Specification
0 = nil / function / thread = 1
1-2 = boolean = 2
3-8 = buffer = 6
9-18 = string = 10
19-82 = custom string = 64 (constants)
83-87 = next_string = 5 (entire next byte for string constants)

88-99 = number = 12
100-123 = custom number = 24 (constants)
124-127 = next_num = 4 (entire next byte is for number constants)

128-149 = vector = 22
150-173 = custom vector = 24 (constants)
174-177 = next_vec = 4 (entire next byte is for vector constants)

178-205 = table = 28

206-211 = userdata = 6 (custom approaches)
212-227 = custom userdata = 16 (constants)
228-231 = next_ud = 4 (entire next byte is for userdata constants)

232-255 = future = 24

Max String Constant Count: 1344
Max Number Constant Count: 1048
Max Vector Constant Count: 1048
Max Userdata Constant Count: 1040
