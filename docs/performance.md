<!--

The speed, memory, and output size will be compared for serialization, while
speed and memory will be compared for deserialization. Depending on the
sample dataset and setup of BufferSerializer, the results will differ wildly.
As such, a variety of datasets will be tested and labeled.

For serialization, compressed output size is also measured, using [???]().

Results will differ based on the platform tested on and whether native-support
is present.

**Compared formats:**
Formats that require Roblox or non-Luau features were excluded.

| Name        | Link                                                      |
|-------------|-----------------------------------------------------------|
| MessagePack | [msgpack-luau](https://github.com/cipharius/msgpack-luau) |
| JSON        | [???]()                                                   |

- For viewing other tested format results, see [???]().
- For viewing results for specific datasets, see [???]().
- For comparisons across versions, see [???]().
- For a guide to benchmarking, see [???]().

-->