# BufferSerializer

[![Luau Version](https://img.shields.io/badge/Luau-0.670+-blue.svg)](https://github.com/luau-lang/luau/releases)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPL_3.0-yellow.svg)](https://opensource.org/licenses/GPL-3.0)

> [!CAUTION]
> Unstable data format, see [migration path](./docs/tips.md#migration).

> [!CAUTION]
> External API is stable, except for the planned addition of errors in a later
>  version.

## Purpose

BufferSerializer is a binary format for complex data structures
 whose goal trudges the line of speed and effective output size.
 Unlike most serializers, BufferSerializer acts as a first-pass compressor
 by storing duplicate data in fewer bytes.  The benefit of this approach is
 that datasets **could** be processed much faster than otherwise, however datasets
 with little duplicate content are less performant.  While the format itself is
 not highly compressible like JSON, there are various approaches to further
 reduce the output size, see [tips](./docs/tips.md#reducing-output-size).

BufferSerializer supports most of the built-in Luau types, excluding `function`
 and `thread`.  Implementations of the binary format in other programming
 languages must follow the [specification](./docs/spec/README.md).

#### Additional Features
- Custom Userdata
  - Users can add support for (de)serializing userdata using the internal API.
- Cyclic tables
  - See [limitations](./docs/risks.md#limitations) for more information.
- Pairs
  - Pays an upfront cost for future duplicates of the paired value to be cheaper.

### Usage Cases
A user needs to prepare data for storing in a database, they will use
 BufferSerializer to convert the data into a buffer, then store the value.

A user with an extension of Luau may wish to have their userdata objects
 specially handled, using BufferSerializer, they create two functions to handle
 the serialization and deserialization of userdata objects.

## Example

More in-depth examples can be found in [examples](./examples), and more
 information about the API is located in the
 [API documentation](./docs/code/README.md).

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