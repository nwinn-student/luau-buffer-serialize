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
- [ ] UNKNOWN [8]: An approach that may be used in the future.

`string`
- [X] empty [9]: The constant `""`
- [X] byte [10]: A string has a length that can be represented as a byte (Takes 2 + strLen bytes)
- [X] char [11]: A string has a length that can be represented as a char (Takes 3 + strLen bytes)
- [X] tryte [12]: A string has a length that can be represented in 3 bytes (Takes 4 + strLen bytes)
- [X] int [13]: A string has a length that can be represented as an int (Takes 5 + strLen bytes)
- [ ] UNKNOWN [14-18]: An approach that may be used in the future.
- [X] byte_constant [19-82]: This byte stores the id of a string constant (1-64)
- [X] char_constant_next [83-87]: The next byte stores the id of a string constant (Takes 2 bytes)

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
- [ ] UNKNOWN [97-99]: An approach that may be used in the future, maybe five_byte/six_byte.
- [X] byte_constant [100-131]: This byte stores the id of a number constant (1-32)
- [X] char_constant_next [132-135]: The next byte stores the id of a number constant (Takes 2 bytes)

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
- [ ] UNKNOWN [150-157]: An approach that may be used in the future.
- [X] byte_constant [158-189]: This byte stores the id of a vector constant (1-32)
- [X] char_constant_next [190-193]: The next byte stores the id of a vector constant (Takes 2 bytes)

`table`  
Definition of array used: An array is a list of elements from index 1 to n where there exist no gaps between the integers 1 and n.  
The arraySize variable represents the amount of bytes used to store all the values within the array part.  The minimum value for arraySize is arrayLen, but such an occurrence is highly unlikely.  

The dictSize variable represents the amount of bytes used to store all the keys and values within the dictionary part.  The minimum value for dictSize is dictLen * 2, but such an occurrence is highly unlikely.

- [X] empty table [194]: The constant ```{}```
- [X] table [195]: A mixed table that contains both arrayend and tableend to terminate. (Takes 3 + arraySize + dictSize bytes)
- [X] equal_to_existing_value [196]: Two bytes of unique values, 61_440 are fixed and 4096 are cycled through (Takes 3 bytes)
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
