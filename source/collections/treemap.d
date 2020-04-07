module collections.treemap;


import collections.commons;
/**
 * Implements an AVL tree backed treemap.
 * Intended to used as an alternative to D's own associative array.
 * If E set to void, then it works more like a regular tree datastructure, and can be indexed with any type K has an
 * opCmp override.
 * Nodes always have the lesser elements on the left side.
 */
public struct TreeMap(K, E, bool nogcIndexing) {
	private struct Node {
		K				key;		///Identifier key, also used for automatic sorting
		static if (E.stringof != "void")
			E			elem;		///The element stored in this field if exists
		Node*			left;		///The node that holds a key with a lesser value
		Node*			right;		///The node that holds a key with a greater value
		string toString() const {
			import std.conv : to;
			string result = "{K: " ~ to!string(key) ~ " ; ";
			static if (E.stringof != "void")
				result ~= "E: " ~ to!string(elem) ~ " ; ";
			if (left) result ~= "Left: " ~ left.toString() ~ " ; ";
			if (right) result ~= "Right: " ~ right.toString() ~ " ; ";
			return result ~ "}";
		}
		///Returns the balance of the node.
		@property sizediff_t balance() @nogc @safe pure nothrow const {
			sizediff_t result;
			if(left) result -= left.height;
			if(right) result += right.height;
			return result;
		}
		///Returns the height of the node.
		@property size_t height() @nogc @safe pure nothrow const {
			const size_t lhs = left ? left.height + 1 : 0;
			const size_t rhs = right ? right.height + 1 : 0;
			return lhs >= rhs ? lhs : rhs;
		}
		static if (E.stringof != "void"){
			/**
			 * Implements a simple left-to-right tree traversal by depth.
			 */
			int opApply(scope int delegate(ref E) dg) {
				if(left)
					if(left.opApply(dg))
						return 1;
				if(dg(elem))
					return 1;
				if(right)
					if(right.opApply(dg))
						return 1;
				return 0;
			}
		} else {
			int opApply(scope int delegate(ref K) dg) {
				if(left)
					if(left.opApply(dg))
						return 1;
				if(dg(key))
					return 1;
				if(right)
					if(right.opApply(dg))
						return 1;
				return 0;
			}
		}
	}
	private size_t		nOfElements;///Current number of elements in this collection
	private Node*		root;		///The root element of the 
	
	static if (E.stringof != "void"){
		static if (nogcIndexing) {
			/**
			 * @nogc capable indexing.
			 * Can be indexed with any type of value as long as K.opCmp supports it.
			 * Returns the found element if match found.
			 * Returns E.init if match not found.
			 */
			E opIndex(T)(T key) @nogc @safe pure nothrow {
				Node* crnt = root;
				while(crnt) {
					if(crnt.key > key) {		//key is smaller than current element's, look at lesser elements
						crnt = crnt.left;
					} else if(crnt.key < key) {			//key is greater than current element's, look at greater elements
						crnt = crnt.right;
					} else {	//match found, return element
						return crnt.elem;
						
					}
				}
				return E.init;
			}
		} else {
			/**
			 * Indexing function that relies on the GC, and throws if no match found
			 * Can be indexed with any type of value as long as K.opCmp supports it.
			 * Returns the found element if match found.
			 */
			E opIndex(T)(T key) @safe pure {
				Node* crnt = root;
				while(crnt) {
					if(crnt.key > key) {		//key is smaller than current element's, look at lesser elements
						crnt = crnt.left;
					} else if(crnt.key < key) {			//key is greater than current element's, look at greater elements
						crnt = crnt.right;
					} else {	//match found, return element
						return crnt.elem;
					}
				}
				throw new ElementNotFoundException("No match found");
			}
		}
	} else {
		static if (nogcIndexing) {
			/**
			 * @nogc capable indexing.
			 * Can be indexed with any type of value as long as K.opCmp supports it.
			 * Returns the found element if match found.
			 * Returns E.init if match not found.
			 */
			K opIndex(T)(T key) @nogc @safe pure nothrow {
				Node* crnt = root;
				while(crnt) {
					if(crnt.key > key) {		//key is smaller than current element's, look at lesser elements
						crnt = crnt.left;
					} else if(crnt.key < key) {			//key is greater than current element's, look at greater elements
						crnt = crnt.right;
					} else {	//match found, return element
						return crnt.key;
					}
				}
				return K.init;
			}
		} else {
			/**
			 * Indexing function that relies on the GC, and throws if no match found
			 * Can be indexed with any type of value as long as K.opCmp supports it.
			 * Returns the found element if match found.
			 */
			K opIndex(T)(T key) @safe pure {
				Node* crnt = root;
				while(crnt) {
					if(crnt.key > key) {		//key is smaller than current element's, look at lesser elements
						crnt = crnt.left;
					} else if(crnt.key < key) {			//key is greater than current element's, look at greater elements
						crnt = crnt.right;
					} else {	//match found, return element
						return crnt.key;
					}
				}
				throw new ElementNotFoundException("No match found");
			}
		}
	}
	/**
	 * Assigns a value to the given key.
	 * If key found, the value will be overwritten without node insertion.
	 * If key isn't found, a new node will be inserted.
	 */
	auto opIndexAssign(E elem, K key) @safe pure nothrow {
		if(!root){	//Best case scenario: root is empty
			nOfElements++;
			root = new Node(key, elem, null, null);
			return elem;
		}
		Node* crnt = root;
		while(crnt) {
			if(crnt.key == key) {	//Another best case scenario: a keymatch is found
				crnt.elem = elem;
				crnt = null;
			} else if(crnt.key > key) {	//Key is smaller, look at left hand side
				if(crnt.left is null) {
					crnt.left = new Node(key, elem, null, null);
					crnt = null;
					nOfElements++;
				}
				else crnt = crnt.left;
			} else {		//Key must be greater, look ay right hand side
				if(crnt.right is null) {
					crnt.right = new Node(key, elem, null, null);
					crnt = null;
					nOfElements++;
				}
				else crnt = crnt.right;
			}
		}
		rebalance();
		return elem;
	}
	static if (E.stringof != "void"){
		/**
		 * Removes an item by key.
		 * Returns the removed item if found, or E.init if not.
		 */
		public E remove(T)(T key) @safe pure nothrow {
			import core.memory : GC;
			Node* crnt = root, prev;
			while(crnt !is null) {
				if(crnt.key > key) {		//Key has a lesser value, search on the left.
					prev = crnt;
					crnt = crnt.left;
				} else if(crnt.key < key) {		//Key has a greater value, search on the right
					prev = crnt;
					crnt = crnt.right;
				} else {				//Key must have been found
					E result = crnt.elem;
					//dispose of the node properly if needed
					if(prev !is null) {
						if(crnt.left && crnt.right) {	//Worst case scenario: find the smallest node on the right hand side
							Node* temp = findMin(crnt.right);
							remove(temp.key);
							crnt.key = temp.key;
							crnt.elem = temp.elem;
						} else if(!crnt.left && crnt.right) {
							if(prev.key > key) {	//The node was on the left side of the previous one
								prev.left = crnt.right;
							} else {
								prev.right = crnt.right;
							}
						} else if(crnt.left && !crnt.right) {
							if(prev.key > key) {	//The node was on the left side of the previous one
								prev.left = crnt.left;
							} else {
								prev.right = crnt.left;
							}
						} else { //Best case scenario: there are no child nodes, just dereference from prev
							if(prev.key > key) {	//The node was on the left side of the previous one
								prev.left = null;
							} else {
								prev.right = null;
							}
						}
					} else {//must be root element
						if(crnt.left && crnt.right) {	//Worst case scenario: find the smallest node on the right hand side
							Node* temp = findMin(crnt.right);
							remove(temp.key);
							crnt.key = temp.key;
							crnt.elem = temp.elem;
						} else if(!crnt.left && crnt.right) {
							root = crnt.right;
						} else if(crnt.left && !crnt.right) {
							root = crnt.left;
						} else { //Best case scenario: there are no child nodes, just dereference from root
							root = null;
						}
					}
					nOfElements--;
					return result;
				}
			}
			return E.init;
		}
	}
	/**
	 * Returns the smallest node
	 */
	private Node* findMin(Node* currentNode) @nogc @safe pure nothrow {
		while(currentNode.left){
			currentNode = currentNode.left;
		}
		return currentNode;
	}
	/**
	 * Rebalances the tree.
	 */
	public void rebalance() @nogc @safe pure nothrow {
		void rebalanceLocal(ref Node* node) @nogc @safe pure nothrow {
			if(node.balance >= 2) {		//Right hand imbalance
				if(node.right.balance > 0) {
					rotateLeft(node);
				} else if(node.right.balance < 0) {
					rotateLeftRight(node);
				}
			} else if(node.balance <= -2) {		//Left hand imbalance
				if(node.left.balance < 0) {
					rotateRight(node);
				} else if(node.left.balance > 0) {
					rotateRightLeft(node);
				}
			}
			if(node.left) rebalanceLocal(node.left);
			if(node.right) rebalanceLocal(node.right);
		}
		rebalanceLocal(root);
	}
	static if (E.stringof != "void"){
		/**
		 * Implements a simple left-to-right tree traversal by depth.
		 */
		int opApply(scope int delegate(ref E) dg) {
			return root.opApply(dg);
		}
	} else {
		/**
		 * Implements a simple left-to-right tree traversal by depth.
		 */
		int opApply(scope int delegate(ref K) dg) {
			return root.opApply(dg);
		}
	}
	/**
	 * Tree rotation for rebalancing.
	 * Rotates the node to the left.
	 */
	private void rotateLeft(ref Node* node) @nogc @safe pure nothrow {
		Node* temp = node.right;
		node.right = temp.left;
		temp.left = node;
		node = temp;
	}
	/**
	 * Tree rotation for rebalancing.
	 * Rotates the node to the left.
	 */
	private void rotateRight(ref Node* node) @nogc @safe pure nothrow {
		Node* temp = node.left;
		node.left = temp.right;
		temp.right = node;
		node = temp;
	}
	/**
	 * Tree rotation for rebalancing.
	 * Rotates the node's right to the left, then the node to the right.
	 */
	private void rotateRightLeft(ref Node* node) @nogc @safe pure nothrow {
		rotateLeft(node.left);
		rotateRight(node);
	}
	/**
	 * Tree rotation for rebalancing.
	 * Rotates the node's left to the right, then the node to the left.
	 */
	private void rotateLeftRight(ref Node* node) @nogc @safe pure nothrow {
		rotateRight(node.right);
		rotateLeft(node);
	}
	/**
	 * returns the string representation of the tree.
	 */
	public string toString() const {
		if(root)
			return root.toString;
		else
			return "Empty";
	}
}

unittest {
	import std.stdio : writeln;
	import std.random : uniform;
	{
		alias IntMap = TreeMap!(int, int, true);
		IntMap test0, test1, test2, test3;
		for(int i ; i < 1024 ; i++)//Stress test to see if large number of elements would cause any issues
			test0[uniform(0, 65536)] = i;
		for(int i ; i < 16 ; i++)
			test1[uniform(0, 65536)] = i;
		writeln(test1.toString);
		for(int i ; i < 32 ; i++)
			test2[uniform(0, 65536)] = i;
		writeln(test2.toString);
		for(int i ; i < 64 ; i++)
			test3[i] = i;
		for(int i ; i < 64 ; i++)
			writeln(test3[i]);
		for(int i ; i < 16 ; i++)
			test3.remove(uniform(0,64));
		foreach(i ; test3)
			writeln(i);
	}
}