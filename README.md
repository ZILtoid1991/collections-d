# collections-d
Advanced data containers for D.

# Currently available containers

|Name:         |Based on:                       |Accessed By:|Adding: |Ordered by: |Theoretical Insertion Complexity:|Theoretical Access Complexity:|Foreach: |Key:|Array:|
|--------------|--------------------------------|------------|--------|------------|---------------------------------|------------------------------|---------|----|------|
|SortedList    |Array with sort per ins.        |Index       |`put` only|Element val.|O(n)                           |O(1)                          |Fwd+Bckwd|None|Yes   |
|SortedSet     |Prev. + check for duplicates    |Index/with `searchBy` function|`put` only|Element val.|O(n)         |O(1) |Fwd+Bckwd|None/with `searchBy` function|Yes   |
|TreeMap       |Self-balancing AVL Tree         |Key         |By key  |Key         |O(log n) + N (balancing)         |O(log n)                |Fwd+Bckwd,K+E,E|Yes |No    |
|TreeSet       |Self-balancing AVL Tree         |Key         |By key  |Key         |O(log n) + N (balancing)         |O(log n)                |Fwd+Bckwd,K+E,E|Yes |No    |
|HashMap       |TreeMap storing hash values     |Key or Hash |By key  |Hashcode's num. value|O(log n) + N (balancing)|O(log n)               |Fwd,HC+E,E|Not preserved|No |
|HashSet       |TreeSet storing hash values     |`has` only, K/H|By key  |Hashcode's num. value|O(log n) + N (balancing)|O(log n)                   |No|Not preserved|No  |
|LinkedList    |Two-way linked list             |Index       |By index, can insert at exact position|None|O(n)       |O(n)                          |Fwd+Bckwd|None|No    |
|LinkedSet     |Prev. + check for duplicates    |Index|`put` only|Similar to FIFO, order can be changed  |O(n)       |O(n)                          |Fwd+Bckwd|None|No    |
|LinkedMap     |Two-way linked list with keys   |Key         |By key  |FIFO        |O(n)                             |O(n)                          |Fwd+Bckwd|Yes |No    |
|LinkedHashMap |Two-way linked list with hash keys|Key or Hash|By key |FIFO        |O(n)           |O(n) |Fwd+Bckwd, Depending on key preservation|Preserved optionally|No|
|LinkedHashSet |LinkedSet storing hash values   |`has` only, K/H|By key  |FIFO        |O(n)                       |O(n)|Only with key preservation|Preserved optionally|No|

A quick note on insertion/access complexity: it does not account things like cache misses and etc. As such, maps will suffer from 
them, and one might have to take things like that into account when designing their software.

## SortedList

An array-backed data structure that enforces the elements stored within itself to be in order. This eliminates the need for frequent
reordering if a regular array was used. Has some optimizations to reduce the search and insertion times.

Has random access for indexing, elements can be only put into the list with the `put()` function.

`alias cmp` can be used both to set how the elements are compared and the way of ordering

### Using as a sorted set

The template of the SortedList can disable duplicates, which will also enable certain functions, like removal by element.

With the `searchBy` template function, the SortedSet can be used similarly to an associative array, but with ordering capabilities.

## TreeMap and TreeSet

Implements an AVL-tree backed associative array. Automatically rebalances itself after each insertion and removal, if imbalance is 
greater or equal than 2. The more elements the tree has, the better the optimization will be.

Accessing is done through keys, and accessing an n-th element needs some computation.

Tree traversal done through `opApply()` and `opApplyReverse()` functions, accessing elements in order when iterated with `foreach`
or `foreach_reverse`.

`alias less` can be used to both set how the keys are compared and whether lesser or greater elements are on the left hand side.

Behavior is changed if E set to void, in that case keys will be the only way the TreeMap stores data, like a regular AVL-tree, or a
treeset.

## HashMap

Implements a hashmap using TreeMap as a backend, and MurMurHash3/32 as the default hashing algorithm. Only can be used with hashing 
algorithms that can be compared similarly to an integer.

## HashSet

Implements a hashset, similarly to hashmap. Operation is done through set operators only, as it only stores the keys of the hashed
elements. Only can be used with hashing algorithms that can be compared similarly to an integer.

## LinkedList

A list with pretty low insertion cost. Ideal for applications where frequent reordering is needed. Can work as a set too by setting
`allowDuplicates` false.

## LinkedMap

Very similar to D's own associative array.

Differentiates keys by checking whether they're equal or not. Has worse access times than TreeMap, but doesn't need optimization during
insertion. Keeps the elements in insertion order, resulting in an ordered map, and behavior in case of key matches can be changed with
template parameter `ovrwrtBhvr`.

## LinkedHashMap

Implements a hashmap, using LinkedMap as a backend, and MurMurHash3/128 as the default hashing algorithm. Can be used with more complex
keys. The backend's `ovrwrtBhvr` template parameter is exposed.

By default keys are not kept, but `retainKeys` changes that, alongside with adding ability of storing multiple keys with matching hash
codes, and foreach capability with keys.

## LinkedHashSet

Implements a hashset, using LinkedList in set mode as a backend, and MurMurHash3/128 as the default hashing algorithm. Can be used with 
more complex keys. Operation is done through set operators only, as it only stores the keys of the hashed elements.

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
* `in`: returns true if key found

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

* Foreach capabilities of many containers are provided through `opApply` operators, which have a complicated
relationship with attributes. A workaround was provided through string mixins and CTFE trickery, but it looks
janky. I'll try to talk with the D community about possible solutions.