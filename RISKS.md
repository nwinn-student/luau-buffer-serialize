# RISKS

This document outlines potential risks associated with the serialization and deserialization of data structures, particularly in the context of Luau tables and the BufferSerializer library. It is crucial to understand these risks to mitigate potential vulnerabilities in applications that utilize these techniques.

### Equal_Existing Approach

The `equal_existing` byte is defined as a way to store a prior unique value in a compressed form.  That is, all unique values are input into a cache and numbered, should the value appear again, the number associated with the value in the cache will be stored.

An attacker could modify the number attached to the `equal_existing` byte to reference a prior unique value.  The resulting behavior is that the attacker could cause an error or freeze to occur when handling the deserialized form.

### Userdata Custom Approach

Requires careful handling to ensure custom serialization and deserialization functions are compatible.


