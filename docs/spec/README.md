<!--

TODO: General information and point to format.md

-->

**Under construction..**

There are 16 approaches left for future applications, whether it be for a new
type in Luau or upon enough user requests.  These approaches will be consumed
when no unknown approach is left in the type's section of the binary format.

There are 16 approaches left for extenders of BufferSerializer to define in
order to accommodate their own requirements, such as adding the length of
tables, re-adding number strings, adding fixed-length strings like
MessagePack, and more.  These 16 approaches will never be consumed by
future BufferSerializer versions.
