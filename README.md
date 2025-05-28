# Buffer Serializer

> Not stable yet

A first pass compressor for numbers, vectors, booleans, and collections thereof.  Strings will not be compressed, thus a second pass compressor is necessary.  Custom types are permitted, and approaches can be added to suit usage cases.  I strongly recommend adding commonly used constants, as it converts X bytes or bits into just one byte.

There are 8 types that can be defined and 32 approaches for each type.  An approach can be a type, but it is usually a constant or it defines how to serialize the data.  The currently added types are `string`, `boolean`, `number`, `vector`, `collection`, with the remaining ones being `custom1`, `custom2`, and `support`, where support is supposed to be a type used to store 32 types if needed.

Numbers are not guaranteed to save bytes.**
Vectors are not guaranteed to save bytes.**
Collections are not guaranteed to save bytes.** (Mainly smaller or mixed types).
Strings take extra bytes, since the length is necessary to know.

Although there is no guarantee, the loss is incredibly minimal, usually a byte or two, which is made up by the saved bytes/bits.  The loss is minimal since there are multiple approaches at play that are compared to see which produces a cheaper output.

# Requirements
Luau 0.670+

# Example Inputs/Outputs
100 is a byte, so we can say it is numberType, byteApproach, 100.  Which totals 1+1=2 bytes (100 -> '100' is 3 bytes, so we save one).

15.5 is a float, so we can say it is numberType, floatApproach, 15.5.  Which totals 1+4=5 bytes (15.5 -> '15.5' is 4 bytes, so we lose one).

(0,1,5) is a vector, so we can say it is vectorType, byteApproach, 0, 1, 5.  Which totals 1+1+1+1=4 bytes ((0,1,5) -> '(0,1,5)' is 7 bytes, so we save three).

(1.5, 2.5, 0.5) is a vector, so we can say it is vectorType, floatApproach, 1.5, 2.5, 0.5.  Which totals 1+4+4+4=13 bytes ((1.5,2.5,0.5) -> '(1.5,2.5,0.5)' is 13 bytes, so we save none).
