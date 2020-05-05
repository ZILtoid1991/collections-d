module collections.commons;

import std.digest.murmurhash;

public class ElementNotFoundException : Exception {
    @nogc @safe pure nothrow this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable nextInChain = null)
    {
        super(msg, file, line, nextInChain);
    }

    @nogc @safe pure nothrow this(string msg, Throwable nextInChain, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line, nextInChain);
    }
}
///Thrown if incorrect arguments are passed to a function
public class IncorrectArgumentsException : Exception {
    @nogc @safe pure nothrow this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable nextInChain = null)
    {
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
uint defaultHash(R)(R src) @trusted pure nothrow {
	ubyte[] helperFunc() @system pure nothrow {
		return cast(ubyte[])(cast(void[])src.dup);
	}
	MurmurHash3!32 hashFunc;
	hashFunc.put(helperFunc);
	hashFunc.finish();
	return hashFunc.get();
}