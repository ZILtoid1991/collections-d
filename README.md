# collections-d
Advanced data containers for D.

# Currently available containers

## SortedList

An array-backed data structure that enforces the elements stored within itself to be in order. This eliminates the need for frequent
reordering if a regular array was used. Has optimizations to reduce the search and insertion times.

Has random access for indexing, elements can be only put into the list with the `put()` function.

`alias cmp` can be used both to set how the elements are compared and the way of ordering

### Using as a sorted set

The template of the SortedList can disable duplicates, which will also enable certain functions, like removal by element.

## TreeMap

Implements an AVL-tree backed associative array. Automatically rebalances itself after each insertion and removal, if imbalance is 
greater or equal than 2. The more elements the tree has, the better the optimization will be.

Accessing is done through keys, and accessing an n-th element needs some computation.

Tree traversal done through `opApply()` and `opApplyReverse()` functions, accessing elements in order when iterated with `foreach`
or `foreach_reverse`.

`alias less` can be used to both set how the keys are compared and whether lesser or greater elements are on the left hand side.

Behavior is changed if E set to void, in that case keys will be the only way the TreeMap stores data, like a regular AVL-tree.