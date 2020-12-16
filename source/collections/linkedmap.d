module collections.linkedmap;

import std.functional : binaryFun;
public import collections.commons;

/**
 * Implements a linked map datastructure.
 * Similar to TreeMap, but instead relies on the equals function, which can mean it can compare keys much easier,
 * meaning much bigger data can be compared easily without hashing. Also it doesn't need to rebalance a tree, which
 * lowers insertion complexity at the cost of higher theoretical access times (n).
 * This linked map has the behavior of putting new elements at the back, resulting in an ordered map similar to
 * what PHP and YAML also has.
 * `ovrwrtBhvr` changes the overwrite behavior when keymatches are found. If true, then if a key is already existing,
 * then it'll overwrite it at the given position. If false, then the matching key will be first deleted, then the
 * new one will be always put in the end.
 */

public struct LinkedMap(K, E, bool nogcIndexing = true, alias equal = "a == b", bool ovrwrtBhvr = true) {
	private struct Node {
		K		key;	///Identifier key
		E		elem;	///Element stored within the node
		Node*	next;	///Next node, null if none exists
		Node*	prev;	///Previous node, null if none exists

		///Keturns a string representation of the node.
		string toString() const {
			import std.conv : to;
			string result = "key: " ~ to!string(key) ~ " ; elem: " ~ to!string(elem);
			if (next) result ~= " ; next: [" ~ next.toString ~ "]";
			return result;
		}
	}
	protected Node*		root;	///Root element.
	protected Node*		last;	///Last element.
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
	/**
	 * opApplyReverse override for foreach.
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
	 * opApplyReverse override for foreach.
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
	static if(nogcIndexing) {
		/**
		 * Returns the element with the given key.
		 * Returns E.init if not found.
		 */
		E opIndex(K key) @nogc @safe pure nothrow {
            Node* crnt = root;
			while (crnt) {
				if (binaryFun!equal(crnt.key, key)) return crnt.elem;
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
				if (binaryFun!equal(crnt.key, key)) return &crnt.elem;
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
				if (binaryFun!equal(crnt.key, key)) return crnt.elem;
				crnt = crnt.next;
			}
			throw new ElementNotFoundException("Key not found!");
		}
	}
	/**
	 * Assigns a value to the given key.
	 */
	auto opIndexAssign(E value, K key) @safe pure nothrow {
		Node** crnt = &root;
		while (*crnt) {
			static if (ovrwrtBhvr) {
				if (binaryFun!equal((*crnt).key, key)) { 
					return (*crnt).elem = value;
				}
			} else {
				if (binaryFun!equal((*crnt).key, key)) {
					if ((*crnt).next) (*crnt).next.prev = (*crnt).prev;
					crnt = &(*crnt).next;
					_length--;
				}
			}
			//prev = crnt;
			crnt = &(*crnt).next;
		}
		//prev.next = new Node(key, value, null);
		*crnt = new Node(key, value, null, *crnt);
		last = *crnt;
		_length++;
		return value;
	}
	/**
	 * Removes a value with the given key and returns it.
	 */
	E remove(K key) @safe pure nothrow {
		Node** crnt = &root;
		while (*crnt) {
			if (binaryFun!equal((*crnt).key, key)) {
				E result = (*crnt).elem;
				//if ((*crnt).prev) (*crnt).prev.next = (*crnt).next;
				if ((*crnt).next is null) last = (*crnt).prev;
				else (*crnt).next.prev = (*crnt).prev;
				*crnt = (*crnt).next;
				_length--;
				return result;
			}
			crnt = &(*crnt).next;
		}
		return E.init;
	}
	/**
	 * Returns true if key is found.
	 */
	bool has(K key) @nogc @safe pure nothrow {
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
	///Returns the string representation of this container format
	string toString() const {
		if (root) return root.toString;
		else return "empty";
	}
}

unittest {
	import std.random : uniform;
	import std.exception : assertThrown;
	import std.stdio : writeln;
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
		foreach_reverse(elem ; test1) {

		}
		foreach_reverse(key, elem ; test1) {

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
	//test FIFO behavior
	{
		alias IntMap = LinkedMap!(int, int, true, "a == b", true);
		IntMap test3;
		test3[0] = 0;
		writeln(test3);
		test3[1] = 1;
		writeln(test3);
		test3[2] = 2;
		writeln(test3);
		test3[3] = 3;
		writeln(test3);
		test3[4] = 4;
		writeln(test3);
		//overwriting key 3 should not distrupt the order
		test3[3] = 5;
		writeln(test3);
	}
	{
		alias IntMap = LinkedMap!(int, int, true, "a == b", false);
		IntMap test3;
		test3[0] = 0;
		writeln(test3);
		test3[1] = 1;
		writeln(test3);
		test3[2] = 2;
		writeln(test3);
		test3[3] = 3;
		writeln(test3);
		test3[4] = 4;
		writeln(test3);
		//overwriting key 3 should put key 3 at the end
		test3[3] = 5;
		writeln(test3);
	}
}