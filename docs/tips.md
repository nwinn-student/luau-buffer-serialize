## Migration

When migrating, the following steps are used.

1. Pass the serialized data into the deserializer, retrieving the original data
2. Pass the original data into the serializer for the desired format or version.

## Reducing output size

1. Reformat the dataset to produce a minimal output size in
 JSON.
   - Easier to iterate since the output is readable.
   - Reductions are often reflected in BufferSerializer.

2. Pair frequently used values.  For more information
 see [pairs](../code/README.md).

3. Convert strings that can be expressed as unions into numbers, identifiers.
   - A `Greeting` union would be "Hello" -> 1, "Hey" -> 2, "What's up" -> 3, etc.
   - **Use with caution.** Haphazard changes to id-value pairs causes migration
 concerns.  See [patch for pairs](https://github.com/nwinn-student/luau-buffer-serialize/discussions/36).

4. Identify whether there are arrays in the dataset with gaps worth filling
 with nil bytes, functions and threads can be used to represent `nil`.
   - In `{ 1, 2, _, 4, 5 }`, where `_` denotes a gap, adding a placeholder function
 will reduce the output size from 14 to 10 bytes.
   - Determining worth requires looking at the output size as combinations of gaps
 are filled.

5. The more known about the dataset, the smaller the output size can be.
   - Knowledge of a dataset's schema (or shape) can be used to morph the dataset
 into a cheaper form (using 3.).
   - Numbers can be compressed when precision is not important.  Ex: A random number (0-1) can be stored as a byte when we only care about nearest 0.005.

