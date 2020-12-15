module collections.linkedhashmap;

import collections.commons;
import std.functional : binaryFun;
import std.traits;

import collections.linkedmap;

/**
 * Implements a linked hashmap.
 * If retainKeys enabled, the map will retain the original keys and hash collisions can be resorted, but can be disabled
 * by setting keyEqual to null.
 * It is a modified linked map, and the `ovrwrtBhvr` still works as with the linked map.
 */
public struct LinkedHashMap(K, E, alias hashFunc = defaultHash128!(K), alias equal = "a == b", bool retainKeys = false,
		alias keyEqual = "a == b", bool ovrwrtBhvr = true) {
	///true if nogc Indexing is enabled.
	static enum bool nogcIndexing = hasFunctionAttributes!(hashFunc, "@nogc");
	alias HashType = ReturnType!hashFunc;
	static if (retainKeys) {
		private struct Node {
			HashType	hashCode;	///Identifier hash
			K			key;		///The key for this node
			E			elem;		///Element stored within the node
			Node*		next;		///Next node, null if none exists
			Node*		prev;		///Previous node, null if none exists
		}
	} else {
		private struct Node {
			HashType	hashCode;	///Identifier hash
			E			elem;		///Element stored within the node
			Node*		next;		///Next node, null if none exists
			Node*		prev;		///Previous node, null if none exists
		}
	}
	protected Node*		root;	///Root element.
	protected Node*		last;	///Last element.
	protected size_t	_length;///N. of currently stored elements
	static if (retainKeys) {
		/**
		 * opApply override for foreach
		 */
		int opApply(scope int delegate(ref E) dg) {
			Node* crnt = root;
			while (crnt) {
				if (dg(crnt.elem)) return 1;
				crnt = crnt.next;
			}
			return 0;
		}
		/**
		 * opApply override for foreach
		 */
		int opApply(scope int delegate(K, ref E) dg) {
			Node* crnt = root;
			while (crnt) {
				if (dg(crnt.key, crnt.elem)) return 1;
				crnt = crnt.next;
			}
			return 0;
		}
		/**
		 * opApplyReverse override for foreach_reverse
		 */
		int opApplyReverse(scope int delegate(ref E) dg) {
			Node* crnt = last;
			while (crnt) {
				if (dg(crnt.elem)) return 1;
				crnt = crnt.prev;
			}
			return 0;
		}
		/**
		 * opApplyReverse override for foreach_reverse
		 */
		int opApplyReverse(scope int delegate(K, ref E) dg) {
			Node* crnt = last;
			while (crnt) {
				if (dg(crnt.key, crnt.elem)) return 1;
				crnt = crnt.prev;
			}
			return 0;
		}
		package static string makeFunc() {
			string makeFuncIndiv(string args) {
				return `
				int opApply(scope int delegate(ref E) ` ~ args ~ ` dg) ` ~ args ~ ` {
					Node* crnt = root;
					while (crnt) {
						if (dg(crnt.elem)) return 1;
						crnt = crnt.next;
					}
					return 0;
				}
				int opApply(scope int delegate(K, ref E) ` ~ args ~ ` dg) ` ~ args ~ ` {
					Node* crnt = root;
					while (crnt) {
						if (dg(crnt.key, crnt.elem)) return 1;
						crnt = crnt.next;
					}
					return 0;
				}
				int opApplyReverse(scope int delegate(ref E) ` ~ args ~ ` dg) ` ~ args ~ ` {
					Node* crnt = last;
					while (crnt) {
						if (dg(crnt.elem)) return 1;
						crnt = crnt.prev;
					}
					return 0;
				}
				int opApplyReverse(scope int delegate(K, ref E) ` ~ args ~ ` dg) ` ~ args ~ ` {
					Node* crnt = last;
					while (crnt) {
						if (dg(crnt.key, crnt.elem)) return 1;
						crnt = crnt.prev;
					}
					return 0;
				}`;
			}
			string result;
			foreach (attr; attrList) {
				result ~= makeFuncIndiv(attr);
			}
			return result;
		}
		mixin(makeFunc);
		/**
		 * Assigns a value to the given key.
		 */
		auto opIndexAssign(E value, K key) @safe pure nothrow {
			const HashType hashCode = hashFunc(key);
			Node** crnt = &root;
			while (*crnt) {
				static if (ovrwrtBhvr) {
					static if (keyEqual !is null) {
						if (binaryFun!equal((*crnt).hashCode, hashCode) && binaryFun!keyEqual((*crnt).key, key)) {
							return (*crnt).elem = value;
						}
					} else {
						if (binaryFun!equal((*crnt).hashCode, hashCode)) {
							(*crnt).key = key;
							return (*crnt).elem = value;
						}
					}
				} else {
					if (binaryFun!equal((*crnt).hashCode, hashCode)) {
						if ((*crnt).prev) (*crnt).prev.next = (*crnt).next;
						*crnt = &(*crnt).next;
						length--;
					}
				}
				crnt = &(*crnt).next;
			}
			//prev.next = new Node(key, value, null);
			*crnt = new Node(key, value, null);
			last = *crnt;
			_length++;
			return value;
		}
		static if (nogcIndexing) {
			
			/**
			 * Returns true if key is found.
			 */
			bool has(K key) @nogc @safe pure nothrow {
				const HashType hash = hashFunc(key);
				Node* crnt = root;
				while (crnt) {
					static if (keyEqual !is null) { 
						if (binaryFun!equal(crnt.hashCode, hash) && binaryFun!keyEqual(crnt.key , key)) {
							return true;
						}
					} else {
						if (binaryFun!equal(crnt.hashCode, hash)) {
							return true;
						}
					}
					crnt = crnt.next;
				}
				return false;
			}
		} else {
			/**
			 * Returns true if key is found.
			 */
			bool has(K key) @safe pure nothrow {
				const HashType hash = hashFunc(key);
				Node* crnt = root;
				while (crnt) {
					static if (keyEqual !is null) { 
						if (binaryFun!equal(crnt.hashCode, hash) && binaryFun!keyEqual(crnt.key , key)) {
							return true;
						}
					} else {
						if (binaryFun!equal(crnt.hashCode, hash)) {
							return true;
						}
					}
					crnt = crnt.next;
				}
				return false;
			}
		}
	} else {
		/**
		 * opApply override for foreach
		 */
		int opApply(scope int delegate(ref E) dg) {
			Node* crnt = root;
			while (crnt) {
				if (dg(crnt.elem)) return 1;
				crnt = crnt.next;
			}
			return 0;
		}
		/**
		 * opApply override for foreach
		 */
		int opApply(scope int delegate(HashType, ref E) dg) {
			Node* crnt = root;
			while (crnt) {
				if (dg(crnt.key, crnt.elem)) return 1;
				crnt = crnt.next;
			}
			return 0;
		}
		/**
		 * opApplyReverse override for foreach_reverse
		 */
		int opApplyReverse(scope int delegate(ref E) dg) {
			Node* crnt = last;
			while (crnt) {
				if (dg(crnt.elem)) return 1;
				crnt = crnt.prev;
			}
			return 0;
		}
		/**
		 * opApplyReverse override for foreach_reverse
		 */
		int opApplyReverse(scope int delegate(HashType, ref E) dg) {
			Node* crnt = last;
			while (crnt) {
				if (dg(crnt.key, crnt.elem)) return 1;
				crnt = crnt.prev;
			}
			return 0;
		}
		package static string makeFunc() {
			string makeFuncIndiv(string args) {
				return `
				int opApply(scope int delegate(ref E) ` ~ args ~ ` dg) ` ~ args ~ ` {
					Node* crnt = root;
					while (crnt) {
						if (dg(crnt.elem)) return 1;
						crnt = crnt.next;
					}
					return 0;
				}
				int opApply(scope int delegate(HashType, ref E) ` ~ args ~ ` dg) ` ~ args ~ ` {
					Node* crnt = root;
					while (crnt) {
						if (dg(crnt.key, crnt.elem)) return 1;
						crnt = crnt.next;
					}
					return 0;
				}
				int opApplyReverse(scope int delegate(ref E) ` ~ args ~ ` dg) ` ~ args ~ ` {
					Node* crnt = last;
					while (crnt) {
						if (dg(crnt.elem)) return 1;
						crnt = crnt.prev;
					}
					return 0;
				}
				int opApplyReverse(scope int delegate(HashType, ref E) ` ~ args ~ ` dg) ` ~ args ~ ` {
					Node* crnt = last;
					while (crnt) {
						if (dg(crnt.key, crnt.elem)) return 1;
						crnt = crnt.prev;
					}
					return 0;
				}`;
			}
			string result;
			foreach (attr; attrList) {
				result ~= makeFuncIndiv(attr);
			}
			return result;
		}
		mixin(makeFunc);
		/**
		 * Assigns a value to the given key.
		 */
		auto opIndexAssign(E value, K key) @safe pure nothrow {
			const HashType hashCode = hashFunc(key);
			Node** crnt = &root;
			while (*crnt) {
				static if (ovrwrtBhvr) {
					if (binaryFun!equal((*crnt).hashCode, hashCode)) return (*crnt).elem = value;
				} else {
					if (binaryFun!equal((*crnt).hashCode, hashCode)) {
						if (&(*crnt).prev) (*crnt).prev.next = (*crnt).next;
						*crnt = &(*crnt).next;
						length--;
					}
				}
				crnt = &(*crnt).next;
			}
			//prev.next = new Node(key, value, null);
			*crnt = new Node(key, value, null);
			last = *crnt;
			_length++;
			return value;
		}
		static if (nogcIndexing) {
			/**
			 * Returns true if key is found.
			 */
			bool has(K key) @nogc @safe pure nothrow {
				return has(hashFunc(key));
			}
		} else {
			/**
			 * Returns true if key is found.
			 */
			bool has(K key) @safe pure {
				return has(hashFunc(key));
			}
		}
	}
	static if (!retainKeys || keyEqual !is null) {
		static if (nogcIndexing) {
			/**
			 * Returns the element with the given key, or E.init if key is not found.
			 */
			E opIndex(K key) @nogc @safe pure nothrow {
				const HashType hashCode = hashFunc(key);
				Node* crnt = root;
				while (crnt) {
					if (binaryFun!equal(crnt.hashCode, hashCode)) return crnt.key;
					crnt = crnt.next;
				}
				return E.init;
			}
			/**
			 * Returns the element with the given key, or E.init if key is not found.
			 */
			E opIndex(HashType hashCode) @nogc @safe pure nothrow {
				Node* crnt = root;
				while (crnt) {
					if (binaryFun!equal(crnt.hashCode, hashCode)) return crnt.key;
					crnt = crnt.next;
				}
				return E.init;
			}
			/**
			 * Returns the pointer to the element with the given key, of null if key is not found.
			 */
			E* getPtr(K key) @nogc @safe pure nothrow {
				const HashType hashCode = hashFunc(key);
				Node* crnt = root;
				while (crnt) {
					if (binaryFun!equal(crnt.hashCode, hashCode)) return &(crnt.key);
					crnt = crnt.next;
				}
				return null;
			}
			/**
			 * Returns the pointer to the element with the given key, of null if key is not found.
			 */
			E* getPtr(HashType hashCode) @nogc @safe pure nothrow {
				Node* crnt = root;
				while (crnt) {
					if (binaryFun!equal(crnt.hashCode, hashCode)) return &(crnt.key);
					crnt = crnt.next;
				}
				return null;
			}
		} else {
			/**
			 * Returns the element with the given key, or E.init if key is not found.
			 */
			ref E opIndex(K key) @nogc @safe pure nothrow {
				const HashType hashCode = hashFunc(key);
				Node* crnt = root;
				while (crnt) {
					if (binaryFun!equal(crnt.hashCode, hashCode)) return crnt.key;
					crnt = crnt.next;
				}
				throw new ElementNotFoundException("Key not found!");
			}
			/**
			 * Returns the element with the given key, or E.init if key is not found.
			 */
			ref E opIndex(HashType hashCode) @nogc @safe pure nothrow {
				Node* crnt = root;
				while (crnt) {
					if (binaryFun!equal(crnt.hashCode, hashCode)) return crnt.key;
					crnt = crnt.next;
				}
				throw new ElementNotFoundException("Key not found!");
			}
		}
	} else {
		static if (nogcIndexing) {
			/**
			 * Returns the element with the given key, or E.init if key is not found.
			 */
			E opIndex(K key) @nogc @safe pure nothrow {
				const HashType hashCode = hashFunc(key);
				Node* crnt = root;
				while (crnt) {
					if (binaryFun!equal(crnt.hashCode, hashCode) && binaryFun!keyEqual(crnt.key, key)) return crnt.key;
					crnt = crnt.next;
				}
				return E.init;
			}
			/**
			 * Returns the pointer to the element with the given key, of null if key is not found.
			 */
			E* getPtr(K key) @nogc @safe pure nothrow {
				const HashType hashCode = hashFunc(key);
				Node* crnt = root;
				while (crnt) {
					if (binaryFun!equal(crnt.hashCode, hashCode) && binaryFun!keyEqual(crnt.key, key)) return &(crnt.key);
					crnt = crnt.next;
				}
				return null;
			}
		} else {
			/**
			 * Returns the element with the given key, or E.init if key is not found.
			 */
			ref E opIndex(K key) @nogc @safe pure nothrow {
				const HashType hashCode = hashFunc(key);
				Node* crnt = root;
				while (crnt) {
					if (binaryFun!equal(crnt.hashCode, hashCode) && binaryFun!keyEqual(crnt.key, key)) return crnt.key;
					crnt = crnt.next;
				}
				throw new ElementNotFoundException("Key not found!");
			}
		}
	}
	/**
	 * Returns true if key is found.
	 */
	bool has(HashType hashCode) @nogc @safe pure nothrow {
		Node* crnt = root;
		while (crnt) {
			if (binaryFun!equal(crnt.key, key)) return true;
			crnt = crnt.next;
		}
		return false;
	}
	/**
	 * Returns the number of elements in the LinkedMap.
	 */
	@property size_t length() @nogc @safe pure nothrow const {
		return _length;
	}
}

unittest {
	alias StringMap = LinkedHashMap!(string, string);
	StringMap d;
	d["AAAAAAAAA"] = "AAAAAAAAA";
	d["Hello World!"] = "Hello Vilag!";
	assert(d["AAAAAAAAA"] == "AAAAAAAAA");
	assert(d["Hello World!"] == "Hello Vilag!");
}