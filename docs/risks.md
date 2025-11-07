#### Limitations
- Although cyclic tables<sup>[1]</sup> are supported, large datasets with
  distant<sup>[2]</sup> cyclic tables will fatally error.  Although possible,
  the solution would be too costly.

<sub>[1]: Tables that point to other tables that at some point, point back to
the initial pointing table.</sub>

<sub>[2]: Large datasets are datasets with at least 61_440 unique values,
including dictionary keys and excluding constants.  Distant cyclic tables
are cyclic tables that are at least 4_096 unique values apart.</sub>