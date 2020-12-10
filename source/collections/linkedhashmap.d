module collections.linkedhashmap;

import collections.commons;
import std.functional : binaryFun;
import std.traits;

import collections.linkedmap;

/**
 * Implements a linked hashmap.
 * If retainKeys enabled, the map will retain the original keys and hash collisions can be resorted, but can be disabled
 * by setting keyEqual to null.
 * It uses a LinkedMap as its backend, and does retain it's ordered map qualities, and the `ovrwrtBhvr` template parameter
 * is exposed.
 */
public struct LinkedHashMap(K, E, alias hashFunc = defaultHash128!(K), alias equal = "a == b", bool retainKeys = false,
		alias keyEqual = "a == b", bool ovrwrtBhvr = true) {
	///true if nogc Indexing is enabled.
	static enum bool nogcIndexing = hasFunctionAttributes!(hashFunc, "@nogc");
	alias HashType = ReturnType!hashFunc;
	static if (retainKeys) {
		///stores a key-element pair
		struct Entry {
			K		key;	///Key of the entry
			E		elem;	///Element of the entry
			static if (keyEqual != "")
				Entry*	next;	///Stores the next entry in case of keyEqual is set
		}
		private LinkedMap!(HashType, Entry, nogcIndexing, equal, ovrwrtBhvr) backend;
	} else {
		private LinkedMap!(HashType, E, nogcIndexing, equal, ovrwrtBhvr) backend;
	}
	static if (nogcIndexing && !retainKeys) {
		/**
		 * Accesses an element within the map.
		 */
		E opIndex(HashType key) @nogc @safe pure nothrow {
			return backend[key];
		}
		///Ditto
		E opIndex(K key) @nogc @safe pure nothrow {
			return backend[hashFunc(key)];
		}
		/**
		 * Returns the pointer of a given element.
		 */
		E* ptrOf(HashType key) @nogc @safe pure nothrow {
			return backend.ptrOf(key);
		}
		///Ditto
		E* ptrOf(K key) @nogc @safe pure nothrow {
			return backend.ptrOf(hashFunc(key));
		}
	} else static if (!nogcIndexing && !retainKeys) {
		/**
		 * Accesses an element within the map.
		 */
		ref E opIndex(K key) @safe pure {
			return backend[hashFunc(key)];
		}
		///Ditto
		ref E opIndex(HashType key) @safe pure {
			return backend[key];
		}
	} else static if (nogcIndexing && retainKeys) {
		/**
		 * Accesses an element within the map.
		 */
		E opIndex(K key) @nogc @safe pure nothrow {
			static if (keyEqual == "") {
				return backend[hashFunc(key)].elem;
			} else {
				Entry e = backend[hashFunc(key)];
				if (binaryFun!keyEqual(key, e.key)) {
					return e.elem;
				} else {
					Entry* crnt = e.next;
					while (crnt) {
						if (binaryFun!keyEqual(key, crnt.key)) 
							return crnt.elem;
						else
							crnt = crnt.next;
					}
				}
				return E.init;
			}
		}
		/**
		 * Returns the pointer of a given element
		 */
		E* ptrOf(K key) @nogc @safe pure nothrow {
			static if (keyEqual == "") {
				return &(backend.ptrOf(hashFunc(key)).elem);
			} else {
				Entry* crnt = backend.ptrOf(hashFunc(key));
				while (crnt) {
					if (binaryFun!keyEqual(key, crnt.key)) 
						return crnt.elem;
					else
						crnt = crnt.next;
				}
				return null;
			}
		}
	} else {
		/**
		 * Accesses an element within the map.
		 */
		ref E opIndex(K key) @safe pure {
			static if (keyEqual == "") {
				return backend[hashFunc(key)].elem;
			} else {
				Entry* crnt = &(backend[hashFunc(key)]);
				while (crnt) {
					if (binaryFun!keyEqual(key, crnt.key)) 
						return crnt.elem;
					else
						crnt = crnt.next;
				}
				throw new ElementNotFoundException("Key not found!");
			}
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