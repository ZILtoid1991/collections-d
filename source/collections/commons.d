module collections.commons;

import std.digest.murmurhash;

///Contains all possible basic attributes that might be used in a foreach situation
static immutable string[] attrList = ["@safe", "@nogc", "nothrow", "pure",
	"@nogc nothrow", "@nogc pure", "nothrow pure", "@nogc nothrow pure", "@safe nothrow",
	"@safe @nogc nothrow", "@safe @nogc pure", "@safe nothrow pure", "@safe @nogc nothrow pure"];
///Generates overrides to be mixed in with regular code
string generateOverrides()(){
	string result;
	foreach (attr; attrList)
		result ~= Func(attr);
	return result;
}
///Thrown if an element is nog found
public class ElementNotFoundException : Exception {
	@nogc @safe pure nothrow this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable nextInChain = null) {
		super(msg, file, line, nextInChain);
	}

	@nogc @safe pure nothrow this(string msg, Throwable nextInChain, string file = __FILE__, size_t line = __LINE__)
	{
		super(msg, file, line, nextInChain);
	}
}
///Thrown if incorrect arguments are passed to a function
public class IncorrectArgumentsException : Exception {
	@nogc @safe pure nothrow this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable nextInChain = null) {
		super(msg, file, line, nextInChain);
	}

	@nogc @safe pure nothrow this(string msg, Throwable nextInChain, string file = __FILE__, size_t line = __LINE__)
	{
		super(msg, file, line, nextInChain);
	}
}
/**
 * Standard digest function for hashing, using the MurMurHash3/32 algorithm
 */
uint defaultHash(R)(R src) @nogc @trusted pure nothrow {
	const (ubyte)[] helperFunc() @nogc @system pure nothrow {
		return cast(const (ubyte)[])(cast(const (void)[])src);
	}
	MurmurHash3!32 hashFunc;
	hashFunc.put(helperFunc);
	hashFunc.finish();
	return hashFunc.get();
}
/**
 * Standard digest function for hashing, using the MurMurHash3/128 algorithm
 */
ubyte[16] defaultHash128(R)(R src) @nogc @trusted pure nothrow {
	const (ubyte)[] helperFunc() @nogc @system pure nothrow {
		return cast(const (ubyte)[])(cast(const (void)[])src);
	}
	MurmurHash3!128 hashFunc;
	hashFunc.put(helperFunc);
	return hashFunc.finish();
}