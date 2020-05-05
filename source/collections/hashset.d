module collections.hashset;

import collections.treemap;
import collections.linkedlist;
import std.traits;
//import std.digest.murmurhash;
public import collections.commons;
/**
 * Implements a hashset, either using collections.treemap or collections.linkedlist as a set for backend.
 * Cannot be accessed directly, instead it can check whether an element is within it or not.
 */
public struct HashSet(K, alias hashFunc = defaultHash!K) {
	alias HashType = ReturnType!hashFunc;
	alias Backend = TreeMap!(HashType, void);
	private Backend			backend;
	/**
	 * Creates a HashSet from a compatible range.
	 */
	public this(R)(R range) @safe pure nothrow {
		foreach(K key; range) put(key);
	}
	/**
	 * Puts an item into the hash set, then returns the generated hashcode.
	 * Returns uint.init if there's a hashcode match.
	 */
	uint put(K key) @safe pure nothrow {
		return backend.put(hashFunc(key));
	}
	/**
	 * Returns true if the element exists within the set, false otherwise.
	 */
	bool has(K key) @safe pure nothrow {
		return backend.has(hashFunc(key));
	}
	/**
	 * Removes an element by match.
	 * Returns the hashcode if found, or uint.init if not.
	 */
	uint removeByElem(K key) @safe pure nothrow {
		return backend.removeByElem(hashFunc(key));
	}
	alias remove = removeByElem;
	/**
	 * Set operators.
	 * Enables math operations on sets, like unions and intersections.
	 * Could work on ranges in general as long as they implement some basic functions, like iteration.
	 */
	HashSet!(K, hashFunc, Backend) opBinary(string op, R)(R rhs) {
		static if(op == "|" || op == "~") {//Union
			HashSet!(K, hashFunc, Backend) result;
			foreach(e ; backend)
				result.put(e);
			foreach(e ; rhs) 
				result.put(e);
			return result;
		} else static if(op == "&" || op == "*") {//Intersection
			HashSet!(K, hashFunc, Backend);
			foreach(e ; rhs){
				if(backend.has(e)) result.put(e);
			}
			return result;
		} else static if(op == "-" || op == "/") {//Complement
			HashSet!(K, hashFunc, Backend) result;
			foreach(e ; backend)
				result.put(e);
			foreach(e ; rhs){
				result.removeByElem(e);
			}
			return result;
		} else static if(op == "^"){//Difference
			HashSet!(K, hashFunc, Backend) result = this | rhs;
			HashSet!(K, hashFunc, Backend) common = this & rhs;
			foreach(e ; common){
				result.removeByElem(e);
			}
			return result;
		} else static assert(0, "Operator " ~ op ~ "not supported");
	}
	/**
	 * Set operators.
	 */
	HashSet!(K, hashFunc, Backend) opOpAssign(string op)(E value) {
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
	HashSet!(K, hashFunc, Backend) opOpAssign(string op, R)(R range) {
		static if(op == "~=" || op == "|=") {//Append
			foreach(val; range)
				put(val);
		} else static if(op == "-=" || op == "/=") {
			foreach(val; range)
				removeByElem(val);
		} else static assert(0, "Operator " ~ op ~ "not supported");
		return this;
	}
}

unittest {
	alias MatchFinder = HashSet!(string);
	MatchFinder set = MatchFinder(["AAAAAA","BBBBBB","CCCCCC","DDDDDD"]);
	assert(set.has("AAAAAA"));
	assert(set.has("BBBBBB"));
	assert(set.has("CCCCCC"));
	assert(set.has("DDDDDD"));
	assert(!set.has("000000"));
}