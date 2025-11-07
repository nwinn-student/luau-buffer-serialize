
## Reducing output size

Reformat the dataset into a form that produces a minimal output size in
 JSON.

Identify whether there are arrays in the dataset with gaps worth filling
     >  with nil bytes, functions and threads can be used to represent `nil`.

Supply known pairs to BufferSerializer.

Reformatting using JSON as a reference is much simpler than understanding how
BufferSerializer internals function in order to reduce the output size.  Most
improvements to the JSON version of the format will improve the output of
BufferSerializer.  The more information known regarding the dataset, the smaller
the output size can be, and at some point, schema-based serializers will be more
optimal, and beyond that a custom-made serializer based on the specific
information.  BufferSerializer sits right before schema-based serializers in
that it assumes less knowledge is known regarding the format and the little
known can be conveyed through pairings and userdata functions.