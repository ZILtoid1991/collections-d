module collections.linkedhashmap;

import collections.commons;
import std.functional : binaryFun;
import std.traits;

import collections.linkedmap;

/**
 * Implements a linked hashmap.
 * 
 */
public struct LinkedHashMap(K, E, alias hashFunc = defaultHash128!(K), alias equal = "a == b") {
	static enum bool nogcIndexing = hasFunctionAttributes!(hashFunc, "@nogc");
	alias HashType = ReturnType!hashFunc;
	private LinkedMap!(HashType, E, nogcIndexing, equal) backend;
	static if (nogcIndexing) {
		/**
		 * Accesses an element within the map.
		 */
		E opIndex(K key) @nogc @safe pure nothrow {
			return backend[hashFunc(key)];
		}
		/**
		 * Returns the pointer of a given element.
		 */
		E* ptrOf(K key) @nogc @safe pure nothrow {
			return backend.ptrOf(hashFunc(key));
		}
	} else {
		/**
		 * Accesses an element within the map.
		 */
		ref E opIndex(K key) @safe pure {
			return backend[hashFunc(key)];
		}
	}
	/**
	 * Assigns an element to a given key.
	 */
	E opIndexAssign(E value, K key) @safe pure nothrow {
		return backend[hashFunc(key)] = value;
	}
	static if(nogcIndexing) {
		/**
		 * Returns true if key is found.
		 */
		bool has(K key) @nogc @safe pure nothrow {
			return backend.has(hashFunc(key));
		}
	} else {
		/**
		 * Returns true if key is found.
		 */
		bool has(K key) @safe pure nothrow {
			return backend.has(hashFunc(key));
		}
	}
	/**
	 * Removes a value with the given key and returns it.
	 */
	E remove(K key) @safe pure nothrow {
		return backend.remove(hashFunc(key));
	}
	/**
	 * Returns the number of elements in the LinkedHashMap.
	 */
	@property size_t length() @nogc @safe pure nothrow const {
		return backend.length;
	}
	/**
	 * opApply override for foreach.
	 */
	int opApply(scope int delegate(ref E) dg) {
		return backend.opApply(dg);
	}
	/**
	 * opApply override for foreach.
	 */
	int opApply(scope int delegate(HashType, ref E) dg) {
		return backend.opApply(dg);
	}
	package static string makeFunc() {
		string makeFundIndiv(string attr) {
			return `int opApply(scope int delegate(ref E) ` ~ attr ~ ` dg) ` ~ attr ~ ` {
		return backend.opApply(dg);
	}
	int opApply(scope int delegate(HashType, ref E) ` ~ attr ~ ` dg) ` ~ attr ~ ` {
		return backend.opApply(dg);
	}`;
		}
		string result;
		foreach (attr; attrList) result ~= makeFundIndiv(attr);
		return result;
	}
	mixin(makeFunc);
}

unittest {
	alias StringMap = LinkedHashMap!(string, string);
	StringMap d;
	d["AAAAAAAAA"] = "AAAAAAAAA";
	d["Hello World!"] = "Hello Vilag!";
	assert(d["AAAAAAAAA"] == "AAAAAAAAA");
	assert(d["Hello World!"] == "Hello Vilag!");
}