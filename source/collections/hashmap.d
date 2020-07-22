module collections.hashmap;

import collections.treemap;
import std.traits;
import std.digest.murmurhash;
public import collections.commons;
/**
 * Implements a hashmap using collections.treemap as a backend.
 * See collections.treemap for more info on certain things.
 */
public struct HashMap(K, E, alias hashFunc = defaultHash!K, alias less = "a < b") {
	static enum bool nogcIndexing = hasFunctionAttributes!(hashFunc, "@nogc");
	alias HashType = ReturnType!hashFunc;
	private TreeMap!(HashType, E, nogcIndexing, less)     backend;

	public void rebalance() @nogc @safe pure nothrow {
		backend.rebalance();
	}
	static if (nogcIndexing) {
		/**
		 * @nogc capable indexing.
		 * Returns the found element if match found.
		 * Returns E.init if match not found.
		 */
		E opIndex(K key) @nogc @safe pure nothrow {
			return backend.opIndex(hashFunc(key));
		}
        ///Ditto
        E opIndex(HashType key) @nogc @safe pure nothrow {
            return backend.opIndex(key);
        }
		/**
		 * Returns the pointer of the element, or null if key not found.
		 */
		E* ptrOf(K key) @nogc @safe pure nothrow {
			return backend.ptrOf(hashFunc(key));
		}
        ///Ditto
        E* ptrOf(HashType key) @nogc @safe pure nothrow {
            return backend.ptrOf(key);
        }
	} else {
		/**
		 * Indexing function that relies on the GC, and throws if no match found.
		 * Returns the found element if match found.
		 */
		ref E opIndex(K key) @safe pure {
			return backend.opIndex(hashFunc(key));
		}
        ///Ditto
        ref E opIndex(HashType key) @safe pure {
			return backend.opIndex(key);
		}
	}
	/**
	 * Assigns an element to the given key.
	 */
	E opIndexAssign(E value, K key) @safe pure nothrow{
		return backend.opIndexAssign(value, hashFunc(key));
	}
	/**
	 * Implements a simple left-to-right tree traversal.
	 */
	int opApply(scope int delegate(ref E) dg) {
		return backend.opApply(dg);
	}
	/**
	 * Implements a simple left-to-right tree traversal.
	 */
	int opApply(scope int delegate(HashType, ref E) dg) {
		return backend.opApply(dg);
	}
	/**
	 * Implements a simple right-to-left tree traversal.
	 */
	int opApplyReverse(scope int delegate(ref E) dg) {
		return backend.opApplyReverse(dg);
	}
	/**
	 * Implements a simple right-to-left tree traversal.
	 */
	int opApplyReverse(scope int delegate(HashType, ref E) dg) {
		return backend.opApplyReverse(dg);
	}
	package static string makeFunc() {
		string makeFundIndiv(string attr) {
			return `int opApply(scope int delegate(ref E) ` ~ attr ~ ` dg) ` ~ attr ~ ` {
		return backend.opApply(dg);
	}
	int opApply(scope int delegate(HashType, ref E) ` ~ attr ~ ` dg) ` ~ attr ~ ` {
		return backend.opApply(dg);
	}
	int opApplyReverse(scope int delegate(ref E) ` ~ attr ~ ` dg) ` ~ attr ~ ` {
		return backend.opApplyReverse(dg);
	}
	int opApplyReverse(scope int delegate(HashType, ref E) ` ~ attr ~ ` dg) ` ~ attr ~ ` {
		return backend.opApplyReverse(dg);
	}`;
		}
		string result;
		foreach (attr; attrList) result ~= makeFundIndiv(attr);
		return result;
	}
	mixin(makeFunc);
	/**
	 * Returns the number of currently held elements within the tree.
	 */
	public @property size_t length() @nogc @safe pure nothrow const {
		return backend.length;
	}
	/**
	 * returns the string representation of the tree.
	 */
	public string toString() const {
		return backend.toString();
	}
}

unittest {
	alias Dictionary = HashMap!(string, string);
	Dictionary d;
	d["AAAAAAAAA"] = "AAAAAAAAA";
	d["Hello World!"] = "Hello Vilag!";
	assert(d["AAAAAAAAA"] == "AAAAAAAAA");
	assert(d["Hello World!"] == "Hello Vilag!");
}