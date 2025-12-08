**Work in progress..**

<!--

<What are we measuring?>
- Size

<Why are we measuring?>
- In order to market the product and see how/where it stands.

<When are we measuring?>
- Every version that causes a change to the format or impacts output size.

<How are we measuring?>
This part is more complex, since there are non-public parts currently.
We first download the necessary JSON datasets, then run the generator cli
 to setup the Luau files.  We then use the benchmark cli to run the
 files and store the results.  Using [???] to read the results.

The speed, memory, and output size will be compared for serialization, while
speed and memory will be compared for deserialization. Depending on the
sample dataset and setup of BufferSerializer, the results will differ wildly.
As such, a variety of datasets will be tested and labeled.

<Mention where to find the datasets and proof of their variety.>

We will be using the Lune runtime and it's serde library to compress the
 serialized data.  The compressed output size will convey how compressible
 the format is.

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