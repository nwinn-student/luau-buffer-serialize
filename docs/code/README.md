<!--

Needs alot of work, can pull from other prs

-->

`serialize(data: any): buffer`: Takes in a value and spits out the serialized
version within a buffer.

`deserialize(data: buffer): any`: Takes in a serialized version of some data
and **recreates** and returns the original data.

`pair(id: number, data: any)`: Links a value to an identifier.