# Buffer Serializer

[![Luau Version](https://img.shields.io/badge/Luau-0.670+-blue.svg)](https://github.com/luau-lang/luau/releases)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPL_3.0-yellow.svg)](https://opensource.org/licenses/GPL-3.0)

> [!CAUTION]
> Unstable format until version 2.0.0

#### Table of Contents
- [Purpose](#purpose)
- [Usage Cases](#usage-cases)
- [Example](#example)
- [Performance](#performance)
- [Technical Details](#technical-details)

## Purpose

BufferSerializer is a general-purpose serializer for complex data structures
 whose goal trudges the line of speed and effective output size.

BufferSerializer acts as a first-pass compressor, meaning that it stores
 duplicate data in fewer bytes.  There are ways to represent commonly used
 values in even fewer bytes, `BufferSerializer.pair`.  There are also
 specialized approaches towards formatting a dataset to further reduce output
 size.

> [!TIP]
> 1. Reformat the dataset into a form that produces a minimal output size in
>  JSON.
> 
> 2. Identify whether there are arrays in the dataset with gaps worth filling
>  with nil bytes, functions and threads can be used to represent `nil`.
> 
> 3. Supply known pairs to BufferSerializer.

Reformatting using JSON as a reference is much simpler than understanding how
 BufferSerializer internals function in order to reduce the output size.  Most
 improvements to the JSON version of the format will improve the output of
 BufferSerializer.  The more information known regarding the dataset, the smaller
 the output size can be, and at some point, schema-based serializers will be more
 optimal, and beyond that a custom-made serializer based on the specific
 information.  BufferSerializer sits right before schema-based serializers in
 that it assumes less knowledge is known regarding the format and the little
 known can be conveyed through pairings and userdata functions.

#### Limitations
 - Although cyclic tables<sup>[1]</sup> are supported, large datasets with
  distant<sup>[2]</sup> cyclic tables will fatally error.  Although possible,
  the solution would be too costly.

<sub>[1]: Tables that point to other tables that at some point, point back to
 the initial pointing table.</sub>

<sub>[2]: Large datasets are datasets with at least 61_440 unique values,
 including dictionary keys and excluding constants.  Distant cyclic tables
 are cyclic tables that are at least 4_096 unique values apart.</sub>

### Usage Cases
A user needs to prepare data for storing in a database, they will use
 BufferSerializer to convert the table with the data into a buffer, then
 passing the buffer to a lossless compressor module such as
 [LibDeflate](https://github.com/safeteeWow/LibDeflate) and store the value.

A user with an extension of Luau may wish to have their userdata objects
 specially handled, using BufferSerializer, they create two functions to handle
 the serialization and deserialization of userdata objects.

## Example

More in-depth examples can be found in [examples](./examples).

```luau
local BufferSerializer = require("./path/to/BufferSerializer")

-- Serialize
local data = "Hello World!"
local output = BufferSerializer.serialize(data)

-- Deserialize
local input = BufferSerializer.deserialize(output)

print(`Initial Data: {data}, Final Data: {input}`)
```

## Performance

BufferSerializer was compared against [@cipharius's MessagePack implementation](https://github.com/cipharius/msgpack-luau)
 and Roblox's implementation of JSON.
The benchmark code can be located [here](../bench-results/bench/compare.luau)
 and personal benchmark results [here](../bench-results/bench/compare_results.txt).  

Results will differ based on the platform tested on and whether native-support
 is present.


## Technical Details

For the binary format BufferSerializer is using to (de)serialize, look to [FORMAT.md](./FORMAT.md).  

There are 16 approaches left for future applications, whether it be for a new
 type in Luau or upon enough user requests.  These approaches will be consumed
 when no unknown approach is left in the type's section of the binary format.

There are 16 approaches left for extenders of BufferSerializer to define in
 order to accommodate their own requirements, such as adding the length of
 tables, re-adding number strings, adding fixed-length strings like
 MessagePack, and more.  These 16 approaches will never be consumed by
 future BufferSerializer versions.

### External API

> [!NOTE]
> The External API is stable, even if the format isn't

`serialize(data: any): buffer`: Takes in a value and spits out the serialized
 version within a buffer.

`deserialize(data: buffer): any`: Takes in a serialized version of some data
 and **recreates** and returns the original data.

`pair(id: number, data: any)`: Links a value to an identifier.
