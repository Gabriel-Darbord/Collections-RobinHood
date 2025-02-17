# Collections-RobinHood

Robin Hood hashing is a technique for implementing hash tables.
It is based on open addressing with a simple but clever twist: as new keys are inserted, old keys are shifted around in such a way that all keys remain reasonably close to the slot to which they were originally hashed.
In particular, the variance in the distance of keys from their "home" slots is minimized.

## Installation

```st
Metacello new
  githubUser: 'Gabriel-Darbord' project: 'Collections-RobinHood' commitish: 'main' path: 'src';
  baseline: 'RobinHoodCollections';
  load
```
