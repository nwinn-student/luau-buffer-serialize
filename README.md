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

BufferSerializer is a general-purpose format for complex data structures
 whose goal trudges the line of speed and effective output size.

Unlike most serializers, BufferSerializer acts as a first-pass compressor
 by storing duplicate data in fewer bytes.  While the format itself is not
 highly compressibly like JSON, there are various approaches to further
 reduce the output size, see [tips](./docs/tips.md#reducing-output-size).

#### Supported Features
- Custom Userdata
- Cyclic tables
  - See [limitations](./docs/risks.md#limitations) for more information.

### Usage Cases
A user needs to prepare data for storing in a database, they will use
 BufferSerializer to convert the data into a buffer, then store the value.

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

**Under construction...**

<!--

For more information on the setup and datasets used, see
 [performance](./docs/performance.md).

Only BufferSerializer, paired-BufferSerializer, and the top 3 measured
 formats for each category will be shown, using the (???)[] dataset.

#### Serialization

| Name             | Speed | Memory | Output | Compressed |
|------------------|-------|--------|--------|------------|
| BufferSerializer |       |        |        |            |
| Paired-BuffSer   |       |        |        |            |

#### Deserialization

| Name             | Speed | Memory |
|------------------|-------|--------|
| BufferSerializer |       |        |
| Paired-BuffSer   |       |        |

-->

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
