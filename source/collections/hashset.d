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
	HashSet!(K, hashFunc) opBinary(string op, R)(R rhs) {
		static if(op == "|" || op == "~") {//Union
			HashSet!(K, hashFunc) result;
			foreach(e ; backend)
				result.put(e);
			foreach(e ; rhs) 
				result.put(e);
			return result;
		} else static if(op == "&" || op == "*") {//Intersection
			HashSet!(K, hashFunc) result;
			foreach(e ; rhs){
				if(backend.has(e)) result.put(e);
			}
			return result;
		} else static if(op == "-" || op == "/") {//Complement
			HashSet!(K, hashFunc) result;
			foreach(e ; backend)
				result.put(e);
			foreach(e ; rhs){
				result.removeByElem(e);
			}
			return result;
		} else static if(op == "^"){//Difference
			HashSet!(K, hashFunc) result = this | rhs;
			HashSet!(K, hashFunc) common = this & rhs;
			foreach(e ; common){
				result.removeByElem(e);
			}
			return result;
		} else static assert(0, "Operator " ~ op ~ "not supported");
	}
	/**
	 * Set operators.
	 */
	HashSet!(K, hashFunc) opOpAssign(string op)(E value) {
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
	HashSet!(K, hashFunc) opOpAssign(string op, R)(R range) {
		static if(op == "~=" || op == "|=") {//Append
			foreach(val; range)
				put(val);
		} else static if(op == "-=" || op == "/=") {
			foreach(val; range)
				removeByElem(val);
		} else static assert(0, "Operator " ~ op ~ "not supported");
		return this;
	}
	private int opApply(scope int delegate(HashType) dg) {
		return backend.opApply(dg);
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

unittest {	///Test set operators
	alias MatchFinder = HashSet!(string);
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