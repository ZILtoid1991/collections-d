module collections.linkedlist;

import collections.commons;
import std.functional : binaryFun;
/**
 * Simple linked list implementation.
 * Has very good insertion speed and deletion speeds, but mediocre access.
 */
public struct LinkedList(E, bool allowDuplicates = true, alias equal = "a == b") {
	private struct Node {
		E               elem;   ///The element hold in this node.
		Node*           next;   ///Points to the next element, null if endpoint.
		
		string toString() const {
			import std.conv : to;
			string result = to!string(elem);
			if (next !is null) result ~= " ; " ~ next.toString();
			return result;
		}
	}
	private size_t		nOfElements;///Current number of elements in this collection
	private Node*		root;		///The root element of the list
	private size_t		begin;		///Front position for foreachable range
	private size_t		end;		///Back position for foreachable range
	/**
	 * Creates a linked list from a compatible range.
	 */
	public this(R)(R range) @safe pure {
		foreach(E elem ; range) {
			put(elem);
		}
	}
	/**
	 * Returns the number of currently held elements within the list.
	 */
	public @property size_t length() @nogc @safe pure nothrow const {
		return nOfElements;
	}
	alias opDollar = length;
	/**
	 * Returns the string representation of the list.
	 */
	public string toString() const {
		if(root !is null)
			return "[" ~ root.toString ~ "]";
		else
			return "Empty";
	}
	/**
	 * Creates a slice from the list.
	 */
	public LinkedList!(E, allowDuplicates, equal) opSlice(size_t start, size_t end) @safe pure nothrow {
		assert(end > start, "Out of bounds error!");
		assert(nOfElements > start, "Out of bounds error!");
		assert(nOfElements >= end, "Out of bounds error!");
		LinkedList!(E, allowDuplicates, equal) result;
		for( ; start < end ; start++) result.put(opIndex(start));
		return result;
	}
	/**
	 * Sets a given element to the top.
	 */
	public E setAsFirst(size_t index) @nogc @safe pure nothrow {
		assert(nOfElements > index, "Out of bounds error!");
		if(index) insertNode(0, removeNode(index));
		return root.elem;
	}
	/+/**
	 * Returns the pointer of a given Node.
	 */
	private Node* getPtr(size_t index) @nogc @safe pure nothrow {
		if(index) return root.getPtr(--index);
		else return root;
	}+/
	private Node* removeNode(size_t index) @nogc @safe pure nothrow {
		Node** crnt = &root;
		while(*crnt) {
			if(!index) {
				Node* backup = *crnt;
				*crnt = (*crnt).next;
				backup.next = null;
				return backup;
			}
			crnt = &(*crnt).next;
			index--;
		}
		return null;
	}
	private void insertNode(size_t index, Node* n) @nogc @safe pure nothrow {
		Node** crnt = &root;
		while(*crnt) {
			if(!index) {
				n.next = *crnt;
				*crnt = n;
				return;
			}
			crnt = &(*crnt).next;
			index--;
		}
		*crnt = n;
	}
	/**
	 * Swaps two elements.
	 */
	public void swap(size_t i0, size_t i1) @nogc @safe pure nothrow {
		assert(nOfElements > i0, "Out of bounds error!");
		assert(nOfElements > i1, "Out of bounds error!");
		if(i0 > i1) {
			const size_t temp = i0;
			i0 = i1;
			i1 = temp;
		}
		Node* n0 = removeNode(i0), n1 = removeNode(i1 - 1);
		insertNode(i0, n1);
		insertNode(i1, n0);
		version (unittest) {
			size_t count;
			Node* crnt = root;
			while (crnt) {
				count++;
				crnt = crnt.next;
			}
			assert(count == nOfElements, "Lenght mismatch error!");
		}
	}
	/**
	 * Removes the given index of the list.
	 * Return the value held at the given position
	 */
	public E remove(size_t index) @safe pure nothrow {
		assert(nOfElements > index, "Out of bounds error!");
		nOfElements--;
		end--;
		return removeNode(index).elem;
	}
	static if(allowDuplicates) {
		/**
		 * Returns the element at the given index.
		 * Will cause segfault if indexed out of bounds.
		 */
		ref E opIndex(size_t index) @nogc @safe pure nothrow {
			assert(index < nOfElements, "Out of bounds error!");
			Node* crnt = root;
			while (index) {
				crnt = crnt.next;
				index--;
			}
			return crnt.elem;
		}
		/**
		 * Assigns an element to the index.
		 */	
		public E opIndexAssign(E value, size_t index) @nogc @safe pure nothrow {
			assert(index < nOfElements, "Out of bounds error!");
			Node* crnt = root;
			while (index) {
				crnt = crnt.next;
				index--;
			}
			return crnt.elem = value;
		}
		/**
		 * Inserts an element at the given index.
		 */
		public E insertAt(E value, size_t index) @safe pure nothrow {
			assert(index <= nOfElements, "Out of bounds error!");
			insertNode(index, new Node(value, null));
			nOfElements++;
			end++;
			return value;
			//return E.init;
		}
		/**
		 * Inserts an element at the end of the list.
		 */
		public E insertAtEnd(E value) @safe pure nothrow {
			return insertAt(value, nOfElements);
		}
		alias put = insertAtEnd;
		/**
		 * Range operators.
		 */
		LinkedList!(E, allowDuplicates, equal) opOpAssign(string op)(E value) {
			static if(op == "~") {//Append
				put(value);
			} else static assert(0, "Operator " ~ op ~ "not supported");
			return this;
		}
		/**
		 * Range operators.
		 */
		LinkedList!(E, allowDuplicates, equal) opOpAssign(string op, R)(R range) {
			static if(op == "~") {//Append
				foreach(E value ; range)
					put(value);
			} else static assert(0, "Operator " ~ op ~ " not supported");
			return this;
		}
		/**
		 * Returns the element at the front.
		 */
		@property ref E frontRef() @nogc @safe nothrow pure {
			return opIndex(begin);
		}
		/**
		 * Returns the element at the back.
		 */
		@property ref E backRef() @nogc @safe nothrow pure {
			return opIndex(end - 1);
		}
	} else {
		/**
		 * Returns the element at the given index.
		 * Will cause segfault if indexed out of bounds.
		 */
		E opIndex(size_t index) @nogc @safe pure nothrow {
			assert(index < nOfElements, "Out of bounds error!");
			Node* crnt = root;
			while (index) {
				crnt = crnt.next;
				index--;
			}
			return crnt.elem;
		}
		/**
		 * Removes an index if the value is found.
		 * Returns the original if found, or E.init if not.
		 */
		public E removeByElem(E value) @safe pure nothrow {
			Node** crnt = &root;
			while(*crnt) {
				if ((*crnt).elem == value) {
					E result = (*crnt).elem;
					*crnt = (*crnt).next;
					return result;
				}
				crnt = &(*crnt).next;
			}
			return E.init;
		}
		/**
		 * Inserts an element at the end of the list.
		 */
		public E put(E value) @safe pure nothrow {
			Node** crnt = &root;
			while (*crnt) {
				if(binaryFun!equal((*crnt).elem, value)) {
					(*crnt).elem = value;
					return value;
				}
				crnt = &(*crnt).next;
			}
			nOfElements++;
			end++;
			*crnt = new Node(value, null);
			return value;
		}
		/**
		 * Returns true if the element is found within the set.
		 */
		public bool has(E value) @nogc @safe pure nothrow {
			Node* crnt = root;
			while (crnt) {
				if (crnt.elem == value) return true;
				crnt = crnt.next;
			}
			return false;
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
		LinkedList!(E, allowDuplicates, equal) opBinary(string op, R)(R rhs) {
			static if(op == "|" || op == "~") {//Union
				LinkedList!(E, allowDuplicates, equal) result;
				for(size_t i; i < nOfElements ; i++) 
					result.put(opIndex(i));
				foreach(e ; rhs)
					result.put(e);
				return result;
			} else static if(op == "&" || op == "*") {//Intersection
				LinkedList!(E, allowDuplicates, equal) result;
				foreach(e ; rhs){
					if(this.has(e)) result.put(e);
				}
				return result;
			} else static if(op == "-" || op == "/") {//Complement
				LinkedList!(E, allowDuplicates, equal) result = LinkedList!(E, allowDuplicates, equal)(this);
				foreach(e ; rhs){
					result.removeByElem(e);
				}
				return result;
			} else static if(op == "^"){//Difference
				LinkedList!(E, allowDuplicates, equal) result = this | rhs;
				LinkedList!(E, allowDuplicates, equal) common = this & rhs;
				foreach(e ; common){
					result.removeByElem(e);
				}
				return result;
			} else static assert(0, "Operator " ~ op ~ "not supported");
		}
		/**
		 * Set operators.
		 */
		LinkedList!(E, allowDuplicates, equal) opOpAssign(string op)(E value) {
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
		LinkedList!(K, E, less) opOpAssign(string op, R)(R range) {
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
	/**
	 * Returns the element at the front.
	 */
	@property E front() @nogc @safe nothrow pure {
		return opIndex(begin);
	}
	/**
	 * Returns the element at the back.
	 */
	@property E back() @nogc @safe nothrow pure {
		return opIndex(end - 1);
	}
	/**
	 * Returns the element at begin and increments the position by one.
	 */
	E moveFront() @nogc @safe nothrow pure {
		E result = opIndex(begin);
		popFront();
		return result;
	}
	/**
	 * Increments the front iteration position by one
	 */
	void popFront() @nogc @safe nothrow pure {
		if(begin < end) begin++;
	}
	/**
	 * Decrements the back iteration position by one
	 */
	void popBack() @nogc @safe nothrow pure {
		if(begin < end) end--;
	}
	/**
	 * Returns true when the end of the list have been reached.
	 */
	@property bool empty() @nogc @safe nothrow pure {
		return begin == end;
	}
	/**
	 * Returns the elements of the list copied into an array.
	 */
	@property E[] arrayOf() @safe nothrow pure {
		E[] result;
		result.reserve(nOfElements);
		Node* crnt = root;
		while (crnt) {
			result ~= crnt.elem;
			crnt = crnt.next;
		}
		return result;
	}
	/**
	 * Returns a copy of this struct.
	 */
	@property auto save() @nogc @safe nothrow pure {
		return this;
	}
	/**
	 * Moves to the n-th position and returns the element of that position.
	 */
	E moveAt(size_t n) @nogc @safe nothrow pure {
		begin = n;
		return opIndex(n);
	}
}

unittest {
	alias LinkedNumList = LinkedList!(int);
	LinkedNumList lnl;
	lnl.put(5);
	lnl.put(8);
	assert(lnl.arrayOf == [5, 8], lnl.toString);
	lnl.put(11);
	lnl.put(9);
	assert(lnl.arrayOf == [5, 8, 11, 9], lnl.toString);
	assert(lnl.length == 4);
	lnl.insertAt(10, 1);
	assert(lnl.length == 5);
	assert(lnl.arrayOf == [5, 10, 8, 11, 9], lnl.toString);
	lnl.remove(1);
	assert(lnl.arrayOf == [5, 8, 11, 9], lnl.toString);
	assert(lnl.length == 4);
	lnl.swap(1,3);
	assert(lnl.arrayOf == [5, 9, 11, 8], lnl.toString);
	lnl.setAsFirst(2);
	assert(lnl.arrayOf == [11, 5, 9, 8], lnl.toString);
	lnl.remove(2);
	assert(lnl.arrayOf == [11, 5, 8], lnl.toString);
	assert(lnl.length == 3);
	lnl ~= [8, 6, 4, 2, 9];
	assert(lnl.arrayOf == [11, 5, 8, 8, 6, 4, 2, 9], lnl.toString);
	assert(lnl[2..6].arrayOf == [8, 8, 6, 4], lnl[2..6].toString);
}

unittest {
	alias LinkedNumSet = LinkedList!(int, false);
	LinkedNumSet sa = LinkedNumSet([-1,5,9,3]), sb = LinkedNumSet([-1,6,6,6,8,10]);
	assert(sa.length == 4);
	assert(sa.arrayOf == [-1,5,9,3], sa.toString);
	assert(sb.length == 4);
	assert(sb.arrayOf == [-1,6,8,10], sa.toString);
	assert(sa.has(-1));
	assert(sb.has(-1));
	assert(!sb.has(0));
	LinkedNumSet sc = sa | sb, sd = sa & sb, se = sa ^ sb;
	assert(sc.length == 7, sc.toString());
	assert(sc.has(-1), sc.toString());
	assert(sc.has(3), sc.toString());
	assert(sc.has(5), sc.toString());
	assert(sc.has(6), sc.toString());
	assert(sc.has(8), sc.toString());
	assert(sc.has(9), sc.toString());
	assert(sc.has(10), sc.toString());
	assert(sd.has(-1), sd.toString());
	assert(!se.has(-1), se.toString());
}

unittest {	//test set operators
	alias IntSet = LinkedList!(int, false);
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