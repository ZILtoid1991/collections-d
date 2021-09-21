module collections.linkedhashset;

import collections.commons;
import collections.linkedlist;
import std.traits : ReturnType, hasFunctionAttributes;

/**
 * Implements linked hashset with a linked set as a backend.
 * Uses an equal method for comparison, meaning it can use complex keys.
 * Has poorer access times compared to the hashset with a binary search tree as a backend, but less costly insertion.
 * Elements cannot be accessed directly, instead it can check whether an element is within it or not.
 * Backend's foreach capability is exposed to iterate over hashcodes.
 */
public struct LinkedHashSet(K, alias hashFunc = defaultHash128!(K), alias equal = "a == b") {
    static enum bool nogcIndexing = hasFunctionAttributes!(hashFunc, "@nogc");
	alias HashType = ReturnType!hashFunc;
    private LinkedList!(HashType, false, equal) backend;
    /**
	 * Creates a LinkedHashSet from a compatible range.
	 */
	public this(R)(R range) @safe pure nothrow {
		foreach(K key; range) put(key);
	}
    /**
	 * Puts an item into the hash set, then returns the generated hashcode.
	 */
    HashType put(K key) @safe pure nothrow {
		return backend.put(hashFunc(key));
	}
    /**
	 * Puts a hashcode into the hash set.
	 */
	private HashType put(HashType key) @safe pure nothrow {
		return backend.put(key);
	}
	/**
	 * Returns true if the element exists within the set, false otherwise.
	 */
	bool has(K key) @safe pure nothrow {
		return backend.has(hashFunc(key));
	}
	auto opBinaryRight(string op)(const K key) @safe pure nothrow {
		static if (op == "in") {
			return has(key);
		} else static assert(0, "Operator not supported!");
	}
	/**
	 * Returns true if the element exists within the set, false otherwise.
	 */
	bool has(HashType key) @safe pure nothrow {
		return backend.has(key);
	}
	auto opBinaryRight(string op)(const HashType key) @safe pure nothrow {
		static if (op == "in") {
			return has(key);
		} else static assert(0, "Operator not supported!");
	}
	/**
	 * Returns the amount of elements found in the set.
	 */
	size_t hasRange(R)(R range) @safe pure nothrow {
		size_t result;
		foreach (key; range) {
			if(has(key)) result++;
		}
		return result;
	}
    /**
	 * Removes an element by match.
	 * Returns the hashcode if found, or uint.init if not.
	 */
	HashType removeByElem(K key) @safe pure nothrow {
		return backend.removeByElem(hashFunc(key));
	}
	/**
	 * Removes an element by hashcode.
	 */
	HashType removeByElem(HashType key) @safe pure nothrow {
		return backend.removeByElem(key);
	}
	alias remove = removeByElem;
    /**
	 * Set operators.
	 * Enables math operations on sets, like unions and intersections.
	 * Could work on ranges in general as long as they implement some basic functions, like iteration.
	 */
	LinkedHashSet!(K, hashFunc, equal) opBinary(string op, R)(R rhs) {
		static if(op == "|" || op == "~") {//Union
			LinkedHashSet!(K, hashFunc, equal) result;
			foreach(e ; backend)
				result.put(e);
			foreach(e ; rhs) 
				result.put(e);
			return result;
		} else static if(op == "&" || op == "*") {//Intersection
			LinkedHashSet!(K, hashFunc, equal) result;
			foreach(e ; rhs){
				if(backend.has(e)) result.put(e);
			}
			return result;
		} else static if(op == "-" || op == "/") {//Complement
			LinkedHashSet!(K, hashFunc, equal) result;
			foreach(e ; backend)
				result.put(e);
			foreach(e ; rhs){
				result.removeByElem(e);
			}
			return result;
		} else static if(op == "^"){//Difference
			LinkedHashSet!(K, hashFunc, equal) result = this | rhs;
			LinkedHashSet!(K, hashFunc, equal) common = this & rhs;
			foreach(e ; common){
				result.removeByElem(e);
			}
			return result;
		} else static assert(0, "Operator " ~ op ~ "not supported");
	}
	/**
	 * Set operators.
	 */
	LinkedHashSet!(K, hashFunc, equal) opOpAssign(string op)(E value) {
		static if(op == "~=") {//Append
			put(value);
		} else static if(op == "-=" || op == "/=") {
			removeByElem(value);
		} else static assert(0, "Operator " ~ op ~ "not supported");
		return this;
	}
	/**
	 * Set operators.
	 */
	LinkedHashSet!(K, hashFunc, equal) opOpAssign(string op, R)(R range) {
		static if(op == "~=" || op == "|=") {//Append
			foreach(val; range)
				put(val);
		} else static if(op == "-=" || op == "/=") {
			foreach(val; range)
				removeByElem(val);
		} else static assert(0, "Operator " ~ op ~ "not supported");
		return this;
	}
	/**
	 * Returns the element at the front.
	 */
	@property HashType front() @nogc @safe nothrow pure {
		return backend.front;
	}
    /**
	 * Returns the element at begin and increments the position by one.
	 */
	HashType moveFront() @nogc @safe nothrow pure {
		return backend.moveFront;
	}
	/**
	 * Increments the front iteration position by one
	 */
	void popFront() @nogc @safe nothrow pure {
		backend.popFront();
	}
    /**
	 * Returns true when the end of the list have been reached.
	 */
	@property bool empty() @nogc @safe nothrow pure {
		return backend.empty;
	}
    /**
	 * Returns a copy of this struct.
	 */
	@property auto save() @nogc @safe nothrow pure {
		return this;
	}
}

unittest {
	alias MatchFinder = LinkedHashSet!(string);
	MatchFinder set = MatchFinder(["AAAAAA","BBBBBB","CCCCCC","DDDDDD"]);
	assert(set.has("AAAAAA"));
	assert("AAAAAA" in set);
	assert(set.has("BBBBBB"));
	assert(set.has("CCCCCC"));
	assert(set.has("DDDDDD"));
	assert(!set.has("000000"));
}

unittest {	///Test set operators
	alias MatchFinder = LinkedHashSet!(string);
	MatchFinder a = MatchFinder(["AAAA", "BBBB", "CCCC", "DDDD", "EEEE"]), b = MatchFinder(["DDDD", "EEEE", "FFFF", "GGGG"]);
	MatchFinder c = MatchFinder(["BBBB", "CCCC", "EEEE", "GGGG"]), d = MatchFinder(["AAAA", "EEEE", "BBBB", "GGGG"]);
	MatchFinder union_ab = a | b, union_ad = a | d;
	assert(union_ab.hasRange(["AAAA", "BBBB", "CCCC", "DDDD", "EEEE", "FFFF", "GGGG"]) == 7);
	assert(union_ad.hasRange(["AAAA", "BBBB", "CCCC", "DDDD", "EEEE", "GGGG"]) == 6);
	MatchFinder intrsctn_ab = a & b, intrsctn_cd = c & d, intrsctn_ac = a & c;
	MatchFinder diff_ab = a ^ b;
	MatchFinder comp_ab = a - b;
	assert(intrsctn_ab.hasRange(["DDDD", "EEEE"]) == 2);
	assert(intrsctn_ac.hasRange(["BBBB", "CCCC", "EEEE"]) == 3);
	assert(intrsctn_cd.hasRange(["BBBB", "GGGG"]) == 2);
	assert(diff_ab.hasRange(["AAAA", "BBBB", "CCCC", "FFFF", "GGGG"]) == 5);
	assert(comp_ab.hasRange(["AAAA", "BBBB", "CCCC"]) == 3);
}