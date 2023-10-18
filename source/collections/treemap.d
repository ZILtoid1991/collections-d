module collections.treemap;

import std.functional : binaryFun;
public import collections.commons;
/**
 * Implements an AVL tree backed treemap.
 * Intended to used as an alternative to D's own associative array.
 * If E set to void, then it works more like a regular tree datastructure (as a tree set), and can be indexed with any
 * type K has an opCmp override.
 * `nogcIndexing` changes the behavior of `opIndex` if no match is found. If set to true, indexing returns the default
 * value if no match found, which will need some design consideration. If set to false, indexing throws an exception
 * if no match found.
 * Nodes should have the lesser elements on the left side, but this behavior can somewhat changed with alias less.
 */
public struct TreeMap(K, E, bool nogcIndexing = true, alias less = "a < b") {
	private struct Node {
		K				key;		///Identifier key, also used for automatic sorting
		static if (typeid(E) !is typeid(void))//(E.stringof != "void")
			E			elem;		///The element stored in this field if exists
		Node*			left;		///The node that holds a key with a lesser value
		Node*			right;		///The node that holds a key with a greater value
		string toString() const {
			import std.conv : to;
			string result = "{K: " ~ to!string(key) ~ " ; ";
			static if (typeid(E) !is typeid(void))
				result ~= "E: " ~ to!string(elem) ~ " ; ";
			if (left) result ~= "L: " ~ left.toString() ~ " ; ";
			if (right) result ~= "R: " ~ right.toString() ~ " ; ";
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
		static if (typeid(E) !is typeid(void)){
			/**
			 * Implements a simple left-to-right tree traversal.
			 */
			int opApply(scope int delegate(ref E) dg) {
				if(left !is null)
					if(left.opApply(dg))
						return 1;
				if(dg(elem))
					return 1;
				if(right !is null)
					if(right.opApply(dg))
						return 1;
				return 0;
			}
			/**
			 * Implements a simple left-to-right tree traversal.
			 */
			int opApply(scope int delegate(K, ref E) dg) {
				if(left !is null)
					if(left.opApply(dg))
						return 1;
				if(dg(key, elem))
					return 1;
				if(right !is null)
					if(right.opApply(dg))
						return 1;
				return 0;
			}
			/**
			 * Implements a simple right-to-left tree traversal.
			 */
			int opApplyReverse(scope int delegate(ref E) dg) {
				if(right !is null)
					if(right.opApplyReverse(dg))
						return 1;
				if(dg(elem))
					return 1;
				if(left !is null)
					if(left.opApplyReverse(dg))
						return 1;
				return 0;
			}
			/**
			 * Implements a simple right-to-left tree traversal.
			 */
			int opApplyReverse(scope int delegate(K, ref E) dg) {
				if(right !is null)
					if(right.opApplyReverse(dg))
						return 1;
				if(dg(key, elem))
					return 1;
				if(left !is null)
					if(left.opApplyReverse(dg))
						return 1;
				return 0;
			}
			///Generates an `opApply` and `opApplyReverse` pair for a TreeMap from potential  attributes 
			package static string makeFuncTMNode() {
				string makeFunc(string attr) {
					return "
						int opApply(scope int delegate(ref E) " ~ attr ~ " dg) " ~ attr ~ " {
							if(left !is null)
								if(left.opApply(dg))
									return 1;
							if(dg(elem))
								return 1;
							if(right !is null)
								if(right.opApply(dg))
									return 1;
							return 0;
						}
						int opApply(scope int delegate(K, ref E) " ~ attr ~ " dg) " ~ attr ~ " {
							if(left !is null)
								if(left.opApply(dg))
									return 1;
							if(dg(key, elem))
								return 1;
							if(right !is null)
								if(right.opApply(dg))
									return 1;
							return 0;
						}
						int opApplyReverse(scope int delegate(ref E) " ~ attr ~ " dg) " ~ attr ~ " {
							if(right !is null)
								if(right.opApplyReverse(dg))
									return 1;
							if(dg(elem))
								return 1;
							if(left !is null)
								if(left.opApplyReverse(dg))
									return 1;
							return 0;
						}
						int opApplyReverse(scope int delegate(K, ref E) " ~ attr ~ " dg) " ~ attr ~ " {
							if(right !is null)
								if(right.opApplyReverse(dg))
									return 1;
							if(dg(key, elem))
								return 1;
							if(left !is null)
								if(left.opApplyReverse(dg))
									return 1;
							return 0;
						}";
				}
				string result;
				foreach (attr; attrList) {
					result ~= makeFunc(attr);
				}
				return result;
			}
			mixin(makeFuncTMNode);
		} else {
			/**
			 * Implements a simple left-to-right tree traversal.
			 */
			int opApply(scope int delegate(K) dg) {
				if(left !is null)
					if(left.opApply(dg))
						return 1;
				if(dg(key))
					return 1;
				if(right !is null)
					if(right.opApply(dg))
						return 1;
				return 0;
			}
			/**
			 * Implements a simple right-to-left tree traversal.
			 */
			int opApplyReverse(scope int delegate(K) dg) {
				if(right !is null)
					if(right.opApply(dg))
						return 1;
				if(dg(key))
					return 1;
				if(left !is null)
					if(left.opApply(dg))
						return 1;
				return 0;
			}
			///Generates an `opApply` and `opApplyReverse` pair for a TreeSet with the supplied attributes
			package static string makeFuncTSNode() {
				string makeFunc(string attr){
					return "int opApply(scope int delegate(K) " ~ attr ~ " dg) " ~ attr ~ " {
						if(left !is null)
							if(left.opApply(dg))
								return 1;
						if(dg(key))
							return 1;
						if(right !is null)
							if(right.opApply(dg))
								return 1;
						return 0;
					}
					int opApplyReverse(scope int delegate(K) " ~ attr ~ " dg) " ~ attr ~ " {
						if(right !is null)
							if(right.opApplyReverse(dg))
								return 1;
						if(dg(key))
							return 1;
						if(left !is null)
							if(left.opApplyReverse(dg))
								return 1;
						return 0;
					}";
				}
				string result;
				foreach (attr; attrList) {
					result ~= makeFunc(attr);
				}
				return result;
			}
			mixin(makeFuncTSNode);
		}
	}
	private size_t		nOfElements;///Current number of elements in this collection
	private Node*		root;		///The root element of the tree
	
	static if (E.stringof != "void") {
		static if (nogcIndexing) {
			/**
			 * @nogc capable indexing.
			 * Returns the found element if match found.
			 * Returns E.init if match not found.
			 */
			E opIndex(const K key) @nogc @safe pure nothrow {
				Node* crnt = root;
				while(crnt) {
					if(binaryFun!less(key, crnt.key)) {		//key is smaller than current element's, look at lesser elements
						crnt = crnt.left;
					} else if(binaryFun!less(crnt.key, key)) {			//key is greater than current element's, look at greater elements
						crnt = crnt.right;
					} else {	//match found, return element
						return crnt.elem;
						
					}
				}
				return E.init;
			}
			/**
			 * Returns the pointer of the element, or null if key not found.
			 */
			E* ptrOf(const K key) @nogc @safe pure nothrow {
				Node* crnt = root;
				while(crnt) {
					if(binaryFun!less(key, crnt.key)) {		//key is smaller than current element's, look at lesser elements
						crnt = crnt.left;
					} else if(binaryFun!less(crnt.key, key)) {			//key is greater than current element's, look at greater elements
						crnt = crnt.right;
					} else {	//match found, return element
						return &crnt.elem;
					}
				}
				return null;
			}
			/**
			 * Returns true if the treemap has the key.
			 */
			bool has(const K key) @nogc @safe pure nothrow {
				return ptrOf(key) !is null;
			}
			auto opBinaryRight(string op, K)(const K key) @nogc @safe pure nothrow {
				static if (op == "in") {
					return has(key);
				} else static assert(0, "Operator not supported!");
			}
		} else {
			/**
			 * Indexing function that relies on the GC, and throws if no match found
			 * Can be indexed with any type of value as long as K.opCmp supports it.
			 * Returns the found element if match found.
			 */
			ref E opIndex(K key) @safe pure {
				Node* crnt = root;
				while(crnt) {
					if(binaryFun!less(key, crnt.key)) {		//key is smaller than current element's, look at lesser elements
						crnt = crnt.left;
					} else if(binaryFun!less(crnt.key, key)) {			//key is greater than current element's, look at greater elements
						crnt = crnt.right;
					} else {	//match found, return element
						return crnt.elem;
					}
				}
				throw new ElementNotFoundException("No match found");
			}
			/**
			 * Returns true if the treemap has the key.
			 */
			bool has(const K key) @nogc @safe pure nothrow {
				Node* crnt = root;
				while(crnt) {
					if(binaryFun!less(key, crnt.key)) {		//key is smaller than current element's, look at lesser elements
						crnt = crnt.left;
					} else if(binaryFun!less(crnt.key, key)) {			//key is greater than current element's, look at greater elements
						crnt = crnt.right;
					} else {	//match found, return element
						return true;
					}
				}
				return false;
			}
			auto opBinaryRight(string op, K)(const K key) @nogc @safe pure nothrow {
				static if (op == "in") {
					return has(key);
				} else static assert(0, "Operator not supported!");
			}
		}
	} else {
		/**
		 * Creates a treeset from a preexisting range.
		 */
		public this(R)(R src) @safe pure nothrow {
			foreach (key; src) put(key);
		}
		/**
		 * Returns true if the element exists within the set, false otherwise.
		 */
		public bool has(T)(const T key) @nogc @safe pure nothrow {
			Node* crnt = root;
			while(crnt) {
				if(binaryFun!less(key, crnt.key)) {		//key is smaller than current element's, look at lesser elements
					crnt = crnt.left;
				} else if(binaryFun!less(crnt.key, key)) {			//key is greater than current element's, look at greater elements
					crnt = crnt.right;
				} else {	//match found, return true
					return true;
				}
			}
			return false;
		}
		auto opBinaryRight(string op, T)(const T key) {
				static if (op == "in") {
					return has(key);
				} else static assert(0, "Operator not supported!");
			}
		/**
		 * Returns the amount of elements found in the set.
		 */
		public size_t hasRange(R)(R range) @nogc @safe pure nothrow {
			size_t result;
			foreach (key; range) {
				if(has(key)) result++;
			}
			return result;
		}
		/**
		 * Set operators.
		 * Enables math operations on sets, like unions and intersections.
		 * Could work on ranges in general as long as they implement some basic functions, like iteration.
		 */
		TreeMap!(K, E, nogcIndexing, less) opBinary(string op, R)(R rhs) {
			static if(op == "|" || op == "~") {//Union
				TreeMap!(K, E, nogcIndexing, less) result;
				foreach(e ; this)
					result.put(e);
				foreach(e ; rhs) 
					result.put(e);
				return result;
			} else static if(op == "&" || op == "*") {//Intersection
				TreeMap!(K, E, nogcIndexing, less) result;
				foreach(e ; rhs){
					if(this.has(e)) result.put(e);
				}
				return result;
			} else static if(op == "-" || op == "/") {//Complement
				TreeMap!(K, E, nogcIndexing, less) result;
				foreach(e ; this)
					result.put(e);
				foreach(e ; rhs){
					result.removeByElem(e);
				}
				return result;
			} else static if(op == "^"){//Difference
				TreeMap!(K, E, nogcIndexing, less) result = this | rhs;
				TreeMap!(K, E, nogcIndexing, less) common = this & rhs;
				foreach(e ; common){
					result.removeByElem(e);
				}
				return result;
			} else static assert(0, "Operator " ~ op ~ "not supported");
		}
		/**
		 * Set operators.
		 */
		TreeMap!(K, E, nogcIndexing, less) opOpAssign(string op)(K value) {
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
		TreeMap!(K, E, nogcIndexing, less) opOpAssign(string op, R)(R range) {
			static if(op == "~=" || op == "|=") {//Append
				foreach(val; range)
					put(val);
			} else static if(op == "-=" || op == "/=") {
				foreach(val; range)
					removeByElem(val);
			} else static assert(0, "Operator " ~ op ~ "not supported");
			return this;
		}
		static if (nogcIndexing) {
			/**
			 * @nogc capable indexing.
			 * Can be indexed with any type of value as long as K.opCmp supports it and `alias less` hasn't been changed.
			 * Returns the found element if match found.
			 * Returns E.init if match not found.
			 */
			K opIndex(T)(T key) @nogc @safe pure nothrow {
				Node* crnt = root;
				while(crnt) {
					if(binaryFun!less(key, crnt.key)) {		//key is smaller than current element's, look at lesser elements
						crnt = crnt.left;
					} else if(binaryFun!less(crnt.key, key)) {			//key is greater than current element's, look at greater elements
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
			 * Can be indexed with any type of value as long as K.opCmp supports it and `alias less` hasn't been changed.
			 * Returns the found element if match found.
			 */
			K opIndex(T)(T key) @safe pure {
				Node* crnt = root;
				while(crnt) {
					if(binaryFun!less(key, crnt.key)) {		//key is smaller than current element's, look at lesser elements
						crnt = crnt.left;
					} else if(binaryFun!less(crnt.key, key)) {			//key is greater than current element's, look at greater elements
						crnt = crnt.right;
					} else {	//match found, return element
						return crnt.key;
					}
				}
				throw new ElementNotFoundException("No match found");
			}
		}
	}
	static if (E.stringof != "void"){
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
				if(binaryFun!less(key, crnt.key)) {	//Key is smaller, look at left hand side
					if(crnt.left is null) {
						crnt.left = new Node(key, elem, null, null);
						crnt = null;
						nOfElements++;
					}
					else crnt = crnt.left;
				} else if(binaryFun!less(crnt.key, key)) {		//Key is greater, look ay right hand side
					if(crnt.right is null) {
						crnt.right = new Node(key, elem, null, null);
						crnt = null;
						nOfElements++;
					}
					else crnt = crnt.right;
				} else {	//Another best case scenario: a keymatch is found
					crnt.elem = elem;
					crnt = null;
				} 
			}
			rebalance();
			return elem;
		}
		/**
		 * Removes an item by key.
		 * Returns the removed item if found, or E.init if not.
		 */
		public E remove(K key) @safe pure nothrow {
			import core.memory : GC;
			Node* crnt = root, prev;
			while(crnt !is null) {
				if(binaryFun!less(key, crnt.key)) {		//Key has a lesser value, search on the left.
					prev = crnt;
					crnt = crnt.left;
				} else if(binaryFun!less(crnt.key, key)) {		//Key has a greater value, search on the right
					prev = crnt;
					crnt = crnt.right;
				} else {				//Keymatch must have been found
					E result = crnt.elem;
					//dispose of the node properly if needed
					if(prev !is null) {
						if(crnt.left && crnt.right) {	//Worst case scenario: find the smallest node on the right hand side
							Node* temp = findMin(crnt.right);
							remove(temp.key);
							crnt.key = temp.key;
							crnt.elem = temp.elem;
							return result;
						} else if(!crnt.left && crnt.right) {
							if(binaryFun!less(key, prev.key)) {	//The node was on the left side of the previous one
								prev.left = crnt.right;
							} else {
								prev.right = crnt.right;
							}
						} else if(crnt.left && !crnt.right) {
							if(binaryFun!less(key, prev.key)) {	//The node was on the left side of the previous one
								prev.left = crnt.left;
							} else {
								prev.right = crnt.left;
							}
						} else { //Best case scenario: there are no child nodes, just dereference from prev
							if(binaryFun!less(key, prev.key)) {	//The node was on the left side of the previous one
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
							return result;
						} else if(!crnt.left && crnt.right) {
							root = crnt.right;
						} else if(crnt.left && !crnt.right) {
							root = crnt.left;
						} else { //Best case scenario: there are no child nodes, just dereference from root
							root = null;
						}
					}
					nOfElements--;
					rebalance();
					return result;
				}
			}
			return E.init;
		}
	} else {
		/**
		 * Puts an element into the treeset
		 */
		public K put(K key) @safe pure nothrow {
			if(!root){	//Best case scenario: root is empty
				nOfElements++;
				root = new Node(key, null, null);
				return key;
			}
			Node* crnt = root;
			while(crnt) {
				if(binaryFun!less(key, crnt.key)) {	//Key is smaller, look at left hand side
					if(crnt.left is null) {
						crnt.left = new Node(key, null, null);
						crnt = null;
						nOfElements++;
					}
					else crnt = crnt.left;
				} else if(binaryFun!less(crnt.key, key)) {		//Key is greater, look ay right hand side
					if(crnt.right is null) {
						crnt.right = new Node(key, null, null);
						crnt = null;
						nOfElements++;
					}
					else crnt = crnt.right;
				} else {	//Kaymatch found
					crnt.key = key;
					crnt = null;
				}
			}
			rebalance();
			return key;
		}
		/**
		 * Removes an item by key.
		 * Returns the removed item if found, or K.init if not.
		 */
		public K removeByElem(K key) @safe pure nothrow {
			import core.memory : GC;
			Node* crnt = root, prev;
			while(crnt !is null) {
				if(binaryFun!less(key,crnt.key)) {		//Key has a lesser value, search on the left.
					prev = crnt;
					crnt = crnt.left;
				} else if(binaryFun!less(crnt.key, key)) {		//Key has a greater value, search on the right
					prev = crnt;
					crnt = crnt.right;
				} else {				//Key must have been found
					K result = crnt.key;
					//dispose of the node properly if needed
					if(prev !is null) {
						if(crnt.left && crnt.right) {	//Worst case scenario: find the smallest node on the right hand side
							Node* temp = findMin(crnt.right);
							remove(temp.key);
							crnt.key = temp.key;
							return result;
						} else if(!crnt.left && crnt.right) {
							if(binaryFun!less(key, prev.key)) {	//The node was on the left side of the previous one
								prev.left = crnt.right;
							} else {
								prev.right = crnt.right;
							}
						} else if(crnt.left && !crnt.right) {
							if(binaryFun!less(key, prev.key)) {	//The node was on the left side of the previous one
								prev.left = crnt.left;
							} else {
								prev.right = crnt.left;
							}
						} else { //Best case scenario: there are no child nodes, just dereference from prev
							if(binaryFun!less(key, prev.key)) {	//The node was on the left side of the previous one
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
							return result;
						} else if(!crnt.left && crnt.right) {
							root = crnt.right;
						} else if(crnt.left && !crnt.right) {
							root = crnt.left;
						} else { //Best case scenario: there are no child nodes, just dereference from root
							root = null;
						}
					}
					nOfElements--;
					rebalance();
					return result;
				}
			}
			return K.init;
		}
		alias remove = removeByElem;
	}
	/**
	 * Returns the smallest node
	 */
	private Node* findMin(Node* currentNode) @nogc @safe pure nothrow {
		while(currentNode.left !is null){
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
		if(root !is null)
			rebalanceLocal(root);
	}
	static if (E.stringof != "void"){
		/**
		 * Implements a simple left-to-right tree traversal.
		 */
		int opApply(scope int delegate(ref E) dg) {
			if(root !is null) return root.opApply(dg);
			else return 0;
		}
		/**
		 * Implements a simple left-to-right tree traversal.
		 */
		int opApply(scope int delegate(K, ref E) dg) {
			if(root !is null) return root.opApply(dg);
			else return 0;
		}
		/**
		 * Implements a simple right-to-left tree traversal.
		 */
		int opApplyReverse(scope int delegate(ref E) dg) {
			if(root !is null) return root.opApplyReverse(dg);
			else return 0;
		}
		/**
		 * Implements a simple right-to-left tree traversal.
		 */
		int opApplyReverse(scope int delegate(K, ref E) dg) {
			if(root !is null) return root.opApplyReverse(dg);
			else return 0;
		}
		///Generates an `opApply` and `opApplyReverse` pair for a TreeMap with the supplied attributes
		package static string makeFuncTM() {
			string makeFunc(string attr) {
				return "int opApply(scope int delegate(ref E) " ~ attr ~ " dg) " ~ attr ~ " {
					if(root !is null) return root.opApply(dg);
					else return 0;
				}
				int opApply(scope int delegate(K, ref E) " ~ attr ~ " dg) " ~ attr ~ " {
					if(root !is null) return root.opApply(dg);
					else return 0;
				}
				int opApplyReverse(scope int delegate(ref E) " ~ attr ~ " dg) " ~ attr ~ " {
					if(root !is null) return root.opApplyReverse(dg);
					else return 0;
				}
				int opApplyReverse(scope int delegate(K, ref E) " ~ attr ~ " dg) " ~ attr ~ " {
					if(root !is null) return root.opApplyReverse(dg);
					else return 0;
				}";
			}
			string result;
			foreach (attr; attrList) {
				result ~= makeFunc(attr);
			}
			return result;
		}
		mixin(makeFuncTM);
	} else {
		/**
		 * Implements a simple left-to-right tree traversal by depth.
		 */
		int opApply(scope int delegate(K) dg) {
			if(root !is null) return root.opApply(dg);
			else return 0;
		}
		/**
		 * Implements a simple right-to-left tree traversal.
		 */
		int opApplyReverse(scope int delegate(K) dg) {
			if(root !is null) return root.opApplyReverse(dg);
			else return 0;
		}
		/**
		 * Returns an array representation of the set.
		 */
		@property K[] arrayOf() {
			K[] result;
			result.reserve(nOfElements);
			int putToResult(K elem) @safe pure nothrow {
				result ~= elem;
				return 0;
			}
			root.opApply(&putToResult);
			return result;
		}
		///Generates an `opApply` and `opApplyReverse` pair for a TreeMap with the supplied attributes
		package static string makeFuncTS() {
			string makeFunc(string attr) {
				return "int opApply(scope int delegate(K) " ~ attr ~ " dg) " ~ attr ~ " {
					if(root !is null) return root.opApply(dg);
					else return 0;
				}
				int opApplyReverse(scope int delegate(K) " ~ attr ~ " dg) " ~ attr ~ " {
					if(root !is null) return root.opApplyReverse(dg);
					else return 0;
				}";
			}
			string result;
			foreach (attr; attrList) {
				result ~= makeFunc(attr);
			}
			return result;
		}
		mixin(makeFuncTS);
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
	 * Returns the number of currently held elements within the tree.
	 */
	public @property size_t length() @nogc @safe pure nothrow const {
		return nOfElements;
	}
	/**
	 * Returns the string representation of the tree.
	 */
	public string toString() const {
		if(root !is null)
			return root.toString;
		else
			return "Empty";
	}
}

unittest {
	import std.stdio : writeln, write;
	import std.random : uniform;
	import std.exception : assertThrown;
	{
		alias IntMap = TreeMap!(int, int, true);
		IntMap test0, test1, test2, test3;
		for(int i ; i < 1024 ; i++)//Stress test to see if large number of elements would cause any issues
			test0[uniform(0, 65_536)] = i;
		foreach(k, e; test0){

		}
		foreach_reverse(k, e; test0){

		}
		for(int i ; i < 16 ; i++)
			test1[uniform(0, 65_536)] = i;
		//writeln(test1.toString);
		for(int i ; i < 32 ; i++)
			test2[uniform(0, 65_536)] = i;
		//writeln(test2.toString);
		for(int i ; i < 64 ; i++)
			test3[i] = i;
		for(int i ; i < 64 ; i++)
			write(test3[i],";");
		writeln();
		assert(5 in test3);
		for(int i ; i < 16 ; i++)
			test3.remove(uniform(0,64));
		foreach(i ; test3)
			write(i,";");
		writeln();
	}
	{
		alias IntMap = TreeMap!(int, int, false);
		IntMap test0, test1;
		for(int i ; i < 64 ; i++)
			test0[i] = i;
		assert(test0.length == 64, "TreeMap length mismatch");
		assertThrown!ElementNotFoundException(test0[420]);
		assertThrown!ElementNotFoundException(test0[666]);
		for(int i ; i < 64 ; i++)
			test0.remove(i);
		assert(test0.length == 0, "Treemap item removal failure");
		for(int i ; i < 16 ; i++) {
			test1[i] = i;
			writeln(test1.toString);
		}
		assert(5 in test1);
	}
	{
		alias IntMap = TreeMap!(int, void, true);
		IntMap test0;
		for(int i ; i < 64 ; i++) {
			test0.put(i);
			//writeln(test0.toString());
		}
		assert(5 in test0);
		assert(test0.length == 64, "TreeMap length mismatch");
		for(int i ; i < 64 ; i++) {
			test0.remove(i);
			//writeln(test0.toString());
		}
		assert(test0.length == 0, "Treemap item removal failure");
	}
	{
		alias IntMap = TreeMap!(int, void, false);
		IntMap test0;
		for(int i ; i < 64 ; i++) {
			test0.put(i);
			//writeln(test0.toString());
		}
		assert(5 in test0);
		assert(test0.length == 64, "TreeMap length mismatch");
		assertThrown!ElementNotFoundException(test0[420]);
		assertThrown!ElementNotFoundException(test0[666]);
		for(int i ; i < 64 ; i++) {
			test0.remove(i);
			writeln(test0.toString());
		}
		assert(test0.length == 0, "Treemap item removal failure");
	}
	{	//test set operators
		alias IntSet = TreeMap!(int, void, true);
		IntSet a = IntSet([1, 3, 5, 7, 9]), b = IntSet([1, 5, 9]), c = IntSet([3, 7]);
		IntSet union_ab = a | b, union_ac = a | c, union_bc = b | c;
		IntSet intrsctn_ab = a & b, intrsctn_ac = a & c;
		IntSet cmplmnt_ab = a - b, cmplmnt_ac = a - c;
		IntSet diff_ab = a ^ b, diff_ac = a ^ c, diff_bc = b ^ c;
		assert(union_ab.hasRange([1, 3, 5, 7, 9]) == 5);
		assert(union_ac.hasRange([1, 3, 5, 7, 9]) == 5);
		assert(union_bc.hasRange([1, 3, 5, 7, 9]) == 5);
		assert(intrsctn_ab.hasRange([1, 5, 9]) == 3);
		assert(intrsctn_ac.hasRange([3, 7]) == 2);
		assert(cmplmnt_ab.hasRange([3, 7]) == 2);
		assert(cmplmnt_ac.hasRange([1, 5, 9]) == 3);
		assert(diff_ab.hasRange([3, 7]) == 2);
		assert(diff_ac.hasRange([1, 5, 9]) == 3);
		assert(diff_bc.hasRange([1, 3, 5, 7, 9]) == 5);
	}
}
@safe pure unittest {
	alias IntMap = TreeMap!(int, int, false);
	IntMap test;
	test[5] = 5;
	test[7] = 7;
	test[3] = 3;
	foreach(elem, key; test) {
		assert(elem == key);
	}
}