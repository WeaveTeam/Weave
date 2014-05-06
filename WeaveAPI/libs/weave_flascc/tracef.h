#ifndef tracef

#include "AS3/AS3.h"

/**
 * Example usage:  tracef("hello %s, %u", "world", 123); // output is "hello world, 123"
 */
#define tracef(...) {\
	size_t __size = 256;\
	char __cstr[__size];\
	AS3_DeclareVar(__astr, String);\
	AS3_CopyCStringToVar(__astr, __cstr, snprintf(__cstr, __size, __VA_ARGS__));\
	AS3_Trace(__astr);\
}
#endif
