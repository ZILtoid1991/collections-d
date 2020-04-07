module collections.sortedlist;

import collections.commons;

/**
 * Implements a sorted list of type T.
 * The container ensures that all of it's elements are ordered after any insertion.
 * Has some optimization to stop searching after a given value has passed.
 * If `order` is true, then the greater values are put in front, otherwise starts with the lesser ones.
 * If `allowDuplicates` set false, the collection will act like a sorted set over an array, and won't allow any insertion of preexisting values.
 * Important: The elements stored within this container must have opCmp override with attributes `@safe`, `nothrow`, `pure`.
 */
public struct SortedList(E, bool order = true, bool allowDuplicates = true) {
	private E[]			_array;		///The array where the elements are stored.
	private size_t		begin;		///The position of the current front iteration.
	private size_t		end;		///The position of the current back iteration.
	/**
	 * Constructs a sorted list out from an array.
	 */
	public this(E[] _array) @safe nothrow pure {
		this._array.reserve = _array.length;
        foreach (E key; _array) {
            put(key);
        }
        assert(this._array.length == _array.length);
        assert(this._array.length == end);
	}
    /**
	 * Adds a new element while keeping the order intact.
	 */
	void put(E a) @safe nothrow pure {
		import std.array : insertInPlace;
		//import std.stdio : write, writeln;
		//write(a, ';');
		static if(!order){
			foreach_reverse(i, b; _array) {
				static if(!allowDuplicates) {
					if(a == b) return;
				} else {
					if(a == b) {
						try {
							insertInPlace(_array, i + 1, a);
						} catch(Exception) {}
						end++;
						return;
					}
				}
				if(a > b) {
					try {
						insertInPlace(_array, i + 1, a);
					} catch(Exception) {}
					end++;
					return;
				}
			}
			_array = a ~ _array;
		} else {
			foreach_reverse(i, b; _array) {
				static if(!allowDuplicates) {
					if(a == b) return;
				} else {
					if(a == b) {
						try {
							insertInPlace(_array, i + 1, a);
						} catch(Exception) {}
						end++;
						return;
					}
				}
				if(a < b) {
					try {
						insertInPlace(_array, i + 1, a);
					} catch(Exception) {}
					//writeln(i);
					end++;
					return;
				}
				//write(i,';');
			}
			_array = a ~ _array;
		}
        end++;
	}
	/+void put(E a) @safe nothrow pure {
		import std.array : insertInPlace;
		foreach_reverse(i, b; _array) {
			static if(!allowDuplicates) {
				if(a == b) return;
			} else {
				if(a == b) {
					try {
						insertInPlace(_array, i + 1, a);
					} catch(Exception) {}
					end++;
					return;
				}
			}
			static if(!order) {	
				if(a > b) {
					try {
						insertInPlace(_array, i + 1, a);
					} catch(Exception) {}
					end++;
					return;
				}
			} else {
				if(a < b) {
					try {
						insertInPlace(_array, i + 1, a);
					} catch(Exception) {}
					end++;
					return;
				}
			}
		}
		static if(!order) _array ~= a;
		else _array = a ~ _array;
        end++;
	}+/
    /**
     * Removes the n-th element while keeping the order intact.
     * Returns the removed element.
     */
    E remove(size_t n) @safe nothrow pure {
        import std.algorithm.mutation : remove;
        E result = _array[n];
        _array = remove(_array, n);
        end--;
        return result;
    }
	static if(!allowDuplicates) {
		/**
		 * Removes the element which is equal with the given one if the template is set to not allow duplicates.
		 * Returns the removed element, or E.init if not found.
		 */
		E removeByElem(E b) @safe nothrow pure {
			import std.algorithm.mutation : remove;
			foreach(i, a; _array) {
				if(a == b) {
					_array = remove(_array, i);
					end--;
					return a;
				}
			}
			return E.init;
		}
		/**
		 * Returns whether the set has the given element.
		 */
		bool has(E elem) @nogc @safe nothrow pure {
			foreach(e; _array) {
				static if(order) {
					if(e == elem) return true;
					else if(e < elem) return false;
				} else {
					if(e == elem) return true;
					else if(e > elem) return false;
				}
			}
			return false;
		}
		/**
		 * Returns the index of the given element, or throws an ElementNotFoundException if not found.
		 */
		size_t which(E elem) @safe pure {
			foreach(size_t i ,E e; _array) {
				static if(order) {
					if(e == elem) return i;
					else if(e < elem) throw new ElementNotFoundException("Element not found!");
				} else {
					if(e == elem) return i;
					else if(e > elem) throw new ElementNotFoundException("Element not found!");
				}
			}
			throw new ElementNotFoundException("Element not found!");
		}
		/**
	 	 * Returns a slice from the list, but the slicing is done by element.
		 * Search is done by boundary.
	 	 */
		SortedList!(E, order, allowDuplicates) sliceByElem(E from, E to) @safe pure {
			size_t f, t;
			foreach(size_t i ,E e; _array) {
				static if(order) {
					if(e <= from) f = i;
				} else {
					if(e >= from) f = i;
				}
			}
			foreach(size_t i ,E e; _array) {
				static if(order) {
					if(e <= to) t = i;
				} else {
					if(e >= to) t = i;
				}
			}
			return opSlice(f, t);
		}
	}
	/**
	 * Returns a copy of this struct.
	 */
	@property auto save() @nogc @safe nothrow pure {
		return this;
	}
	/**
	 * Returns the element at the front.
	 */
	@property E front() @nogc @safe nothrow pure {
		return _array[begin];
	}
	/**
	 * Returns the element at the front.
	 */
	@property ref E frontRef() @nogc @safe nothrow pure {
		return _array[begin];
	}
	/**
	 * Returns the element at the back.
	 */
	@property E back() @nogc @safe nothrow pure {
		return _array[end - 1];
	}
	/**
	 * Returns the element at the back.
	 */
	@property ref E backRef() @nogc @safe nothrow pure {
		return _array[end - 1];
	}
	/**
	 * Returns the element at begin and increments the position by one.
	 */
	E moveFront() @nogc @safe nothrow pure {
		E result = _array[begin];
		popFront();
		return result;
	}
	/**
	 * Increments the front iteration position by one
	 */
	void popFront() @nogc @safe nothrow pure {
		if(begin < end) begin++;
	}
	/**
	 * Decrements the back iteration position by one
	 */
	void popBack() @nogc @safe nothrow pure {
		if(begin < end) end--;
	}
	/**
	 * Returns true when the end of the list have been reached.
	 */
	@property bool empty() @nogc @safe nothrow pure {
		return begin == end;
	}
	/**
	 * Returns the n-th element.
	 */
	E opIndex(size_t n) @nogc @safe nothrow pure {
		return _array[n];
	}
	/**
	 * Moves to the n-th position and returns the element of that position.
	 */
	E moveAt(size_t n) @nogc @safe nothrow pure {
		begin = n;
		return _array[begin];
	}
	/**
	 * Returns the length of the list.
	 */
	@property size_t length() @nogc @safe nothrow pure {
		return _array.length;
	}
	alias opDollar = length;
	/**
	 * Returns a slice from the list.
	 */
	SortedList!(E, order, allowDuplicates) opSlice(size_t i0, size_t i1) @safe nothrow pure {
		return SortedList!(E, order, allowDuplicates)(_array[i0..i1]);
	}
	/**
	 * Returns a copy of the underlying array.
	 */
	@property E[] arrayOf() @safe nothrow pure const {
		return _array.dup;
	}
	string toString() {
		import std.conv : to;
		return to!string(_array);
	}
}

@safe unittest {
	import std.stdio : writeln;
	alias SortedIntList = SortedList!(int, true, true);
	alias SortedIntSet = SortedList!(int, true, false);
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
	SortedIntSet sis;
	sis.put(5);
	assert(sis.arrayOf == [5], sis.toString);
	sis.put(5);
	assert(sis.arrayOf == [5], sis.toString);
	sis.put(3);
	assert(sis.arrayOf == [5, 3], sis.toString);
	sis.put(3);
	assert(sis.arrayOf == [5, 3], sis.toString);
	sis.put(7);
	assert(sis.arrayOf == [7, 5, 3], sis.toString);
	sis.put(7);
	assert(sis.arrayOf == [7, 5, 3], sis.toString);
	sis.put(-2);
	assert(sis.arrayOf == [7, 5, 3, -2], sis.toString);
	sis.put(11);
	assert(sis.arrayOf == [11, 7, 5, 3, -2], sis.toString);
	assert(!sis.has(12), sis.toString);
	assert(sis.has(11), sis.toString);
	sis.remove(0);
	assert(!sis.has(11), sis.toString);
	assert(sis.arrayOf == [7, 5, 3, -2], sis.toString);
	sis.put(1);
	assert(sis.arrayOf == [7, 5, 3, 1, -2], sis.toString);
	sis.put(1);
	assert(sis.arrayOf == [7, 5, 3, 1, -2], sis.toString);
	foreach(e; sil) {
		writeln(e);
	}
	foreach(e; sis) {
		writeln(e);
	}
}

@safe unittest {
	import std.stdio : writeln;
	alias SortedIntList = SortedList!(int, false, true);
	alias SortedIntSet = SortedList!(int, false, false);
	SortedIntList sil;
	sil.put(5);
	assert(sil.arrayOf == [5], sil.toString);
	sil.put(3);
	assert(sil.arrayOf == [3, 5], sil.toString);
	sil.put(7);
	assert(sil.arrayOf == [3, 5, 7], sil.toString);
	sil.put(-1);
	assert(sil.arrayOf == [-1, 3, 5, 7], sil.toString);
	sil.remove(2);
	assert(sil.arrayOf == [-1, 3, 7], sil.toString);
	sil.put(2);
	assert(sil.arrayOf == [-1,2, 3, 7], sil.toString);
	SortedIntSet sis;
	sis.put(5);
	assert(sis.arrayOf == [5], sis.toString);
	sis.put(5);
	assert(sis.arrayOf == [5], sis.toString);
	sis.put(3);
	assert(sis.arrayOf == [3, 5], sis.toString);
	sis.put(3);
	assert(sis.arrayOf == [3, 5], sis.toString);
	sis.put(7);
	assert(sis.arrayOf == [3, 5, 7], sis.toString);
	sis.put(7);
	assert(sis.arrayOf == [3, 5, 7], sis.toString);
	sis.put(-2);
	assert(sis.arrayOf == [-2, 3, 5, 7], sis.toString);
	sis.put(11);
	assert(sis.arrayOf == [-2, 3, 5, 7, 11], sis.toString);
	assert(!sis.has(12), sis.toString);
	assert(sis.has(11), sis.toString);
	sis.remove(0);
	assert(!sis.has(-2), sis.toString);
	assert(sis.arrayOf == [3, 5, 7, 11], sis.toString);
	sis.put(1);
	assert(sis.arrayOf == [1, 3, 5, 7, 11], sis.toString);
	sis.put(1);
	assert(sis.arrayOf == [1, 3, 5, 7, 11], sis.toString);
	foreach(e; sil) {
		writeln(e);
	}
	foreach(e; sis) {
		writeln(e);
	}
}