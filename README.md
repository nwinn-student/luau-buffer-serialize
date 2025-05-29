# Buffer Serializer

> Not stable yet

A first pass compressor for numbers, vectors, booleans, and collections thereof.  A second pass is recommended using some lossless compression module as no string manipulation is occurring within this module, except behind the scenes by the buffer library.  Custom types are permitted, and approaches can be added to suit usage cases.  I strongly recommend adding commonly used constants, as it converts X bytes or bits into just one byte.

There are 8 types that can be defined and 32 approaches for each type.  An approach can be a type, but it is usually a constant or it defines how to serialize the data.  The currently added types are `string`, `boolean`, `number`, `vector`, `collection`, with the remaining ones being `custom1`, `custom2`, and `support`, where support is supposed to be a type used to store 32 types if needed.

Numbers are not guaranteed to save bytes.**

Vectors are not guaranteed to save bytes.**

Collections are not guaranteed to save bytes.** (Mainly smaller or mixed types result in a loss).

Strings are just collections using a specific format.  Vectors are just fixed size collections.

Although there is no guarantee, the loss is incredibly minimal, usually a byte or two, which is made up by the saved bytes/bits.  The loss is minimal since there are multiple approaches at play that are compared to see which produces a cheaper output.

# Requirements
Luau 0.670+

# Usage Cases
Storing data in a database, transmitting data to a shared source.

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
- [ ] five_byte: Represents that the number is 5 bytes (Takes 6 byte) (Uncertain since it requires a hacky solution)
- [ ] six_byte: Represents that the number is 6 bytes (Takes 7 byte) (Uncertain since it requires a hacky solution)
- [X] float: Represents that the number is a float (4 bytes) (Takes 5 byte)
- [X] double: Represents that the number is a double (8 bytes) (Takes 9 byte)

Uses 5 bits to represent the size of the number in bits (0 size means 0 and 1 size means 1) (May not be used in `number`, but in `vector`, `collection`, `string`, uncertain.)
- [ ] bit_pos_int: Says to look at the next X bits for a positive integer (Takes 1+0.625+0.25 = 1.875 to 1+0.625+4 = 5.625 bytes)
- [ ] bit_neg_int: Says to look at the next X bits for a negative integer (Takes 1.875 to 5.625 bytes)
- [ ] bit_int: Uses an extra bit to determine pos/neg (Takes 1+0.75+0.25 = 2 to 1+0.75+4 = 5.75 bytes)
- [ ] bit_pos_float: Says to look at the next X bits for a positive float (I will be converting the float into an integer***) (Takes 1.875 to 5.625 bytes)
- [ ] bit_neg_float: Says to look at the next X bits for a negative float (Takes 1.875 to 5.625 bytes)
- [ ] bit_float: Uses an extra bit to determine pos/neg (Takes 2 to 5.75 bytes)
- [ ] bit_int_and_float: Uses two extra bits to determine float/int and pos/neg (Takes 1+0.875+0.25 = 2.125 to 1+0.875+4 = 5.875 bytes)
- [ ] bit_all: Uses 3 extra bits to determine float/double/int/long and pos/neg, uncertain if converting double/long to int is worth it. (Takes 1+1+0.25 = 2.25 to 1+1+4 = 6 bytes)

 * Converting a float to an integer is necessary since we cannot easily save bits for floats by looking at the most significant bit as with ints.
 * I am using floor(log_2 (n + 1) * 2^25 ) to compress and 2^(n / 2^25) - 1 to expand, the accuracy hit should be minimal.
 * Changing 2^25 to 2^22 is used to compress/expand doubles into ints, however there is an accuracy hit.
 * Changing 2^25 to 2^26 is used to compress/expand longs into ints, however there is an even greater accuracy hit since longs are not supported within Luau.

`vector`: (X, Y, Z), All of which are floats.
 - [X] zero: The constant `(0,0,0)` (Takes 1 byte)
 - [X] one: The constant `(1,1,1)` (Takes 1 byte)
 - [X] x_axis: The constant `(1,0,0)` (Takes 1 byte)
 - [X] y_axis: The constant `(0,1,0)` (Takes 1 byte)
 - [X] z_axis: The constant `(0,0,1)` (Takes 1 byte)
 - [X] xy_axis: The constant `(1,1,0)` (Takes 1 byte)
 - [X] yz_axis: The constant `(0,1,1)` (Takes 1 byte)
 - [X] byte: Represents that all three values are bytes (Takes 4 byte)
 - [X] char: Represents that all three values are chars (Takes 7 byte)
 - [X] three_byte: Represents that all three values are three_bytes (Takes 10 byte)
 - [X] float: Represents that all three values are floats (Takes 13 byte, worst case)
 - [X] number: Represents that at least one of the values is of a different type (Takes 1+1+1+2 = 5 to 1+5+5+4 = 15 bytes)
 - [X] scalar_byte: Represents that the vector is a byte multiple of one of the constants (Takes 1+1+1 = 3 bytes)
 - [X] scalar_char: Represents that the vector is a char multiple of one of the constants (Takes 1+2+1 = 4 bytes)
 - [X] scalar_three_byte: Represents that the vector is a three_byte multiple of one of the constants (Takes 1+3+1 = 5 bytes)
 - [X] scalar_float: Represents that the vector is a float multiple of one of the constants (Takes 1+4+1 = 6 bytes)

Operations, so (x, x+a, x+a+b), if a=b then just plus, else plus_2
 - [X] plus: TODO (Takes 1+1+1 = 3 to 1+5+5 = 11 bytes)
 - [X] times: TODO (Takes 3 to 11 bytes)
 - [X] divide: TODO (Takes 3 to 11 bytes)
 - [X] plus_2: TODO (Takes 1+1+1+1 = 4 to 1+5+5+5 = 16 bytes)
 - [X] times_2: TODO (Takes 4 to 16 bytes)
 - [X] divide_2: TODO (Takes 4 to 16 bytes)
 - [ ] dot: TODO (not dot product) ()
 - [ ] to_byte: TODO ()
 - [ ] to_char: TODO ()
 - [ ] bit_number: TODO ()
