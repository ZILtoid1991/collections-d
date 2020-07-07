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

Behavior is changed if E set to void, in that case keys will be the only way the TreeMap stores data, like a regular AVL-tree, or a
treeset.

## HashMap

Implements a hashmap using TreeMap as a backend, and MurMurHash3/32 as the hashing algorithm. Future versions will allow using 
LinkedList as a backend if needed.

## HashSet

Implements a hashset, similarly to hashmap. Operation is done through set operators only, as it only stores the keys of the hashed
elements.

## LinkedList

A list with pretty low insertion cost. Ideal for applications where frequent reordering is needed. Can work as a set too by setting
`allowDuplicates` false.

# Code example

```D
    //I recommend using an alias to shorten the declaration of types.
    alias SortedIntList = SortedList!(int, "a < b", true);
    SortedIntList sil;
	sil.put(5);
	assert(sil.arrayOf == [5], sil.toString);
	sil.put(3);
	assert(sil.arrayOf == [5, 3], sil.toString);
	sil.put(7);
	assert(sil.arrayOf == [7, 5, 3], sil.toString);
	sil.put(-1);
	assert(sil.arrayOf == [7, 5, 3, -1], sil.toString);
	sil.remove(2);
	assert(sil.arrayOf == [7, 5, -1], sil.toString);
	sil.put(2);
	assert(sil.arrayOf == [7 ,5, 2, -1], sil.toString);
    //This will print out the numbers in order, beginning with the greatest
    foreach (int i ; sil)
        writeln(i);
```

# Set operators

The library has some standardized set operators, repurposing preexisting operators found in D.

* `|` and `~`: union
* `&` and `*`: intersection
* `-` and `/`: complement
* `^`: difference

```D
    alias IntSet = TreeMap!(int, void, true);
    alias SortedIntSet = SortedList!(int, "a < b", false);
    IntSet a = IntSet([5, 8, 9, 1]);
    SortedIntSet b = SortedIntSet([6, 8, 9, 3]);
    //Set operators work between different types of sets.
    //The LHS type will decide what the result type will be
    IntSet intr = a & b;
    SortedIntSet diff = b ^ a;
    //RHS range can be of a non-set type, e.g. an array
    IntSet uni = a | [6, 5, 4, -1];
```

# Known issues

* TreeMap/TreeSet (and in turn, HashMap) foreach is done through the `opApply` operator, which provides a delegate to call for each 
item. At the moment, it cannot be used within safe, pure, or nothrow code. For the while, it'll be fixed with a template mixin, that'll
generate functions with the appropriate templates.