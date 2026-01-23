## Technical Details

All approaches that take more than one byte are specified, alongside how many bytes they may take.

For strings and buffers, the data following the final length byte is equivalent to the data within the string/buffer.

For numbers, the data following the representation byte is equivalent to the little-endian representation of the number in bytes.

 - Corrupted data will be returned as nil.

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

`string`
- [X] empty [8]: The constant `""`
- [X] byte [9]: A string has a length that can be represented as a byte (Takes 2 + strLen bytes)
- [X] char [10]: A string has a length that can be represented as a char (Takes 3 + strLen bytes)
- [X] tryte [11]: A string has a length that can be represented in 3 bytes (Takes 4 + strLen bytes)
- [X] int [12]: A string has a length that can be represented as an int (Takes 5 + strLen bytes)
- [X] string_1 [13]: A string has a length of 1 (Takes 2 bytes) Taken from MessagePack, saves 1 byte for short strings
- [X] string_2 [14]: A string has a length of 2 (Takes 3 bytes)
- [X] string_3 [15]: A string has a length of 3 (Takes 4 bytes)
- [X] string_4 [16]: A string has a length of 4 (Takes 5 bytes)
- [X] string_5 [17]: A string has a length of 5 (Takes 6 bytes)
- [X] string_6 [18]: A string has a length of 6 (Takes 7 bytes)
- [X] string_7 [19]: A string has a length of 7 (Takes 8 bytes)
- [X] string_8 [20]: A string has a length of 8 (Takes 9 bytes)
- [X] string_9 [21]: A string has a length of 9 (Takes 10 bytes)
- [X] string_10 [22]: A string has a length of 10 (Takes 11 bytes)
- [X] string_11 [23]: A string has a length of 11 (Takes 12 bytes)
- [X] string_12 [24]: A string has a length of 12 (Takes 13 bytes)
- [X] string_13 [25]: A string has a length of 13 (Takes 14 bytes)
- [X] string_14 [26]: A string has a length of 14 (Takes 15 bytes)
- [X] string_15 [27]: A string has a length of 15 (Takes 16 bytes)
- [X] byte_constant [28-91]: This byte stores the id of a string constant (1-64)
- [X] char_constant_next [92-96]: The next byte stores the id of a string constant (Takes 2 bytes)

`number`
- [X] zero [97]: The constant `0`
- [X] one [98]: The constant `1`
- [X] byte [99]: The number is a byte (Takes 2 byte)
- [X] char [100]: The number is a char (2 bytes) (Takes 3 byte)
- [X] tryte [101]: The number is 3 bytes (Takes 4 byte)
- [X] int [102]: The number is an int (4 bytes) (Takes 5 byte)
- [X] float [103]: The number is a float (4 bytes) (Takes 5 byte)
- [X] double [104]: The number is a double (8 bytes) (Takes 9 byte)
- [X] nan [105]: The constant `nan` or `0/0`.
- [X] byte_constant [106-137]: This byte stores the id of a number constant (1-32)
- [X] char_constant_next [138-141]: The next byte stores the id of a number constant (Takes 2 bytes)

`vector`: (X, Y, Z), All of which are floats (vector is immutable!).
- [X] zero [142]: The constant `(0,0,0)`
- [X] one [143]: The constant `(1,1,1)`
- [X] x_axis [144]: The constant `(1,0,0)`
- [X] y_axis [145]: The constant `(0,1,0)`
- [X] z_axis [146]: The constant `(0,0,1)`
- [X] xy_axis [147]: The constant `(1,1,0)`
- [X] xz_axis [148]: The constant `(1,0,1)`
- [X] yz_axis [149]: The constant `(0,1,1)`
- [X] byte [150]: All three values are bytes (Takes 4 bytes)
- [X] char [151]: All three values are chars (Takes 7 bytes)
- [X] tryte [152]: All three values are three_bytes (Takes 10 bytes)
- [X] float [153]: All three values are floats (Takes 13 bytes, worst case) 
- [X] number [154]: At least one of the values is of a different type (Takes 4 to 15 bytes) 
- [X] scalar_number [155]: The vector is a multiple of an above constant vector (Takes 3 to 7 bytes)
- [ ] UNKNOWN [156-157]: An approach that may be used in the future.
- [X] byte_constant [158-189]: This byte stores the id of a vector constant (1-32)
- [X] char_constant_next [190-193]: The next byte stores the id of a vector constant (Takes 2 bytes)

`table`  
Definition of array used: An array is a list of elements from index 1 to n where there exist no gaps between the integers 1 and n.  
The arraySize variable represents the amount of bytes used to store all the values within the array part.  The minimum value for arraySize is arrayLen, but such an occurrence is highly unlikely.  

The dictSize variable represents the amount of bytes used to store all the keys and values within the dictionary part.  The minimum value for dictSize is dictLen * 2, but such an occurrence is highly unlikely.

- [X] empty table [194]: The constant ```{}```
- [X] table [195]: A mixed table that contains both arrayend and tableend to terminate. (Takes 3 + arraySize + dictSize bytes)
- [X] existing_value [196]: Two bytes of unique values, 61_440 are fixed and 4096 are cycled through (Takes 3 bytes)
- [X] array [197]: An array that uses tableend to terminate (Takes 2 + arraySize bytes)
- [X] dict [198]: A dictionary that uses tableend to terminate (Takes 2 + dictSize bytes) 
- [X] arrayend [199]: Used to terminate the array portion of a table
- [X] tableend [200]: Used to terminate a table
- [ ] UNKNOWN [201]: An approach that may be used in the future.

`userdata`
- [X] custom [202]: A user-defined function is used to read/write the information associated with the userdata (Takes 1+custom bytes)
- [X] nil [203]: Specifies that the userdata is not supported.
- [X] byte_constant [204-213]: This byte stores the id of a userdata constant (1-10)
- [X] char_constant_next [214-215]: The next byte stores the id of a userdata constant (Takes 2 bytes)

`future`
- [ ] future_approaches [216-239]: Approaches reserved for new types or expanding upon prior.

`extend`
- [ ] extend_approaches [240-255]: Approaches reserved for BufferSerializer extenders.
