## Migration

When migrating, the following steps are used.

1. Pass the serialized data into the deserializer, retrieving the original data
2. Pass the original data into the serializer for the desired format or version.

## Reducing output size

1. Reformat the dataset into a form that produces a minimal output size in
 JSON.
  - Easier to iterate since the output is readable.
  - Improvements here often reflect in BufferSerializer, except number to
 string precision reduction and a few other edge cases.
  - Userdata and vectors will need to be converted into tables, strings, or
 numbers.  When switching to BufferSerializer, both can be swapped back in.

2. Find strings, numbers, vectors, or userdata that is repeatedly stored in
 the dataset and pair the values to identifiers.

3. Convert strings that can be expressed as unions into numbers, ids.
  - A `Greeting` union would be "Hello" -> 1, "Hey" -> 2, "What's up" -> 3, etc.
  - **Use with caution.** The ids must be unchanged through future versions,
 thus avoid when the union is not guaranteed to be fixed.
  - This approach produces smaller output sizes than the built-in duplicate
 value approach, going from N + 3M to 2M (assuming -128-127 as id range) where
 N is cost of initial string and M is number of usages.
  - History: Initially pairs used this approach, however it lead to **migration
 concerns** and was revamped to store the value-identifier pair first, then solely
 the identifier on subsequent usages.

4. Identify whether there are arrays in the dataset with gaps worth filling
 with nil bytes, functions and threads can be used to represent `nil`.
  - In `{ 1, 2, _, 4, 5 }`, where `_` denotes a gap, adding a placeholder function
 will reduce the output size from 14 to 10 bytes.
  - Determining worth requires looking at the output size as combinations of gaps
 are filled.

5. The more known about the dataset, the smaller the output size can be.
  - Knowledge of a dataset's schema (or shape) can be used to morph the dataset
 into a cheaper form (using 3.).  Ideally, the dataset would be wrapped to provide
 users a better experience.
  - Numbers can be compressed when precision is not important.  Such as storing a
 random number between 0 and 1, which is only checked to the nearest 0.005, can be
 converted into a byte (5/9 -> 2).

