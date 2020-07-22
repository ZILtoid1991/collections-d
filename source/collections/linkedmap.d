module collections.linkedmap;

import std.functional : binaryFun;
public import collections.commons;

/**
 * Implements a linked map datastructure.
 * Similar to TreeMap, but instead relies on the equals function, which can mean it can compare keys much easier,
 * meaning much bigger data can be compared easily without hashing. Also it doesn't need to rebalance a tree, which
 * lowers insertion complexity at the cost of higher theoretical access times (n).
 */

public struct LinkedMap(K, E, bool nogcIndexing = true, alias equal = "a == b") {
	private struct Node {
		K		key;	///Identifier key
		E		elem;	///Element stored within the node
		Node*	next;	///Next node, null if none exists
	}
	protected Node*		root;	///Root element.
	protected size_t	_length;///N. of currently stored elements
	/**
	 * opApply override for foreach.
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
	 * opApply override for foreach.
	 */
	int opApply(scope int delegate(K, ref E) dg) {
		Node* crnt = root;
		while (crnt) {
			if (dg(crnt.key, crnt.elem)) return 1;
			crnt = crnt.next;
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
			}`;
		}
		string result;
		foreach (attr; attrList) {
			result ~= makeFuncIndiv(attr);
		}
		return result;
	}
	mixin(makeFunc);
	static if(nogcIndexing) {
		/**
		 * Returns the element with the given key.
		 * Returns E.init if not found.
		 */
		E opIndex(K key) @nogc @safe pure nothrow {
            Node* crnt = root;
			while (crnt) {
				if (crnt.key == key) return crnt.elem;
				crnt = crnt.next;
			}
			return E.init;
		}
		/**
		 * Returns the pointer of the element with the given key.
		 * Returns null if not found.
		 */
		E* ptrOf(K key) @nogc @safe pure nothrow {
			Node* crnt = root;
			while (crnt) {
				if (crnt.key == key) return &crnt.elem;
				crnt = crnt.next;
			}
			return null;
		}
	} else {
		/**
		 * Returns the element with the given key.
		 * Returns E.init if not found.
		 */
		ref E opIndex(K key) @safe pure {
            Node* crnt = root;
			while (crnt) {
				if (crnt.key == key) return crnt.elem;
				crnt = crnt.next;
			}
			throw new ElementNotFoundException("Key not found!");
		}
	}
	/**
	 * Assigns a value to the given key.
	 */
	auto opIndexAssign(E value, K key) @safe pure nothrow {
		/+if(!root) {
			root = new Node(key, value, null);
			_length++;
			return value;
		}+/
		Node** crnt = &root;
		while (*crnt) {
			if ((*crnt).key == key) return (*crnt).elem = value;
			//prev = crnt;
			crnt = &(*crnt).next;
		}
		//prev.next = new Node(key, value, null);
		*crnt = new Node(key, value, null);
		_length++;
		return value;
	}
	/**
	 * Removes a value with the given key and returns it.
	 */
	E remove(K key) @safe pure nothrow {
		if (root.key == key) {
			_length--;
			E result = root.elem;
			root = root.next;
			return result;
		}
		Node* crnt = root.next, prev = root;
		while (crnt) {
			if (crnt.key == key) {
				_length--;
				E result = root.elem;
				prev.next = crnt.next;
				return result;
			}
			prev = crnt;
			crnt = crnt.next;
		}
		return E.init;
	}
	/**
	 * Returns true if key is found.
	 */
	bool has(K key) @nogc @safe pure nothrow {
		Node* crnt = root;
		while (crnt) {
			if (crnt.key == key) return true;
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
	import std.random : uniform;
	import std.exception : assertThrown;
	{
		alias IntMap = LinkedMap!(int, int);
		IntMap test0, test1;
		test0[0] = 0;
		test0[0] = 1;
		test0[1] = 1;
		test0[2] = 1;
		test0[3] = 1;
		test0[4] = 1;
		assert(test0.length == 5, "length mismatch!");
		test0.remove(3);
		assert(test0.length == 4, "item deletion error!");
		assert(test0.ptrOf(0), "pointer error!");
		assert(!test0.ptrOf(10), "pointer error!");

		for(int i ; i < 256 ; i++)
			test1[i] = uniform(0, 65_536);
		assert(test1.length == 256, "length mismatch!");
		foreach(elem ; test1) {

		}
		foreach(key, elem ; test1) {

		}
	}
	{
		alias IntMap = LinkedMap!(int, int, false);
		IntMap test2;
		test2[0] = 1;
		test2[1] = 1;
		test2[2] = 1;
		test2[3] = 1;
		test2[4] = 1;
		assertThrown!ElementNotFoundException(test2[8]);
	}
}