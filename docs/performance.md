**What are we measuring?**
- The output size of datasets when serialized using
 BufferSerializer, w/ and w/o pairs.
- The output size of compressed BufferSerializer forms.

**Where do the datasets come from?**
- binary-json-size-benchmark, which provides a variety of
 common datasets
- awesome json datasets(?), which provides a sample of larger
 datasets

**Why are we measuring?**
- In order to market the product and see how/where it stands.
- In order to market the version, or PR, and see the implications of using.

**When are we measuring?**
- Every version that causes a change to the format or impacts output size.

**How are we measuring?**
We have a multi-step process.
- Download the resources (datasets and luau-bench)
- Run the generate-scripts CLI to setup the Luau files
- Run the benchmark CLI to run the files and store the results
- Run the output-size CLI to read the results

We will be using the Lune runtime and it's serde library to compress the
 serialized data.

**Below is WIP**

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