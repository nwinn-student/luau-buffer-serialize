# Buffer Serializer

> Design Stage: In Progress

#### Table of Contents
- [Purpose](#purpose)
- [Requirements](#requirements)
- [Usage Cases](#usage-cases)
- [Example](#example)
- [Performance](#performance)
- [Technical Details](#technical-details)
- [Constant Amount Supported](#constant-amount-supported)


## Purpose

BufferSerializer is a general-purpose serializer for complex data structures with the capability to compress known constants whose goal tredges the line of speed and effective output size.

#### Limitations
 - Although cyclic tables<sup>[1]</sup> are supported, large datasets with distant<sup>[2]</sup> cyclic tables will fatally error.

<sub>[1]: Tables that point to other tables that at some point point back to the initial pointing table.</sub>

<sub>[2]: Large datasets are datasets with at least 61_440 unique values, including dictionary keys and excluding constants.  Distant cyclic tables are cyclic tables that are at least 4_096 unique values apart.</sub>


### Requirements
[Luau 0.670+](https://github.com/luau-lang/luau/releases): As internal methods may shift to use @self to refer to each other.

### Usage Cases
A user needs to prepare data for storing in a database, they will use BufferSerializer to convert the table with the data into a buffer, then passing the buffer to a lossless compressor module such as [LibDeflate](https://github.com/safeteeWow/LibDeflate) and store the value.

A user with an extension of Luau may wish to have their userdata objects specially handled, using BufferSerializer, they create two functions to handle the serialization and deserialization of userdata objects.  


## Example

More in-depth examples can be found in [examples](./examples).

```luau
local bufferSerial = require("./BufferSerializer/BufferSerializer")

-- Serialize
local data = "Hello World!"
local output = BufferSerialize.serialize(data)

-- Deserialize
local input = BufferSerialize.deserialize(output)

print(`Initial Data: {data}, Final Data: {input}`)
```

## Performance

BufferSerializer was compared against Roblox's JSONEncode/Decode and @cipharius's MessagePack.  The benchmark data can be located [here](./bench/compare.luau) and personal benchmark results [here](./bench/compare_results.txt).  Results will differ based on the platform tested on.


## Technical Details

For the binary format BufferSerializer is using to (de)serialize, look to [FORMAT.md](./FORMAT.md).  There are 24 approaches left for future applications, whether it be for a new type in Luau or upon enough user requests.  These approaches will be consumed when no unknown approach is left in the type's section of the binary format.

`serialize(data: any): buffer`: Takes in a value and spits out the serialized version within a buffer.

`deserialize(data: buffer): any`: Takes in a serialized version of some data and **recreates** and returns the original data.

`pair(id: number, data: any)`: Connects a constant value to an identifier.  See [constants supported](#constant-amount-supported) in order to understand how expensive the constant will be in its serialized form.  

### Constant Amount Supported

Constants are used to save the as much output size as possible given **fixed** information.  The constants should seldomly be modified as there is risk of corruption if mishandled.

 - NaN values are NOT supported, such as vector.create(2, 4, 0/0).
 - Userdata values should be handled with care*.  Prioritize pairing lightuserdata objects or known fixed userdata objects.  Do NOT expect userdata objects, like Roblox Instances, to equal other Roblox Instances with the same properties.

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