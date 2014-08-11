/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of the Weave API.
 *
 * The Initial Developer of the Weave API is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2012
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * ***** END LICENSE BLOCK ***** */

#ifndef tracef

#include <stdio.h>
#include "AS3/AS3.h"

/**
 * Example usage:  tracef("hello %s, %u", "world", 123); // output is "hello world, 123"
 */
#define tracef(...) {\
	size_t size = 256;\
	char cstr[size];\
	AS3_DeclareVar(tracef_str, String);\
	AS3_CopyCStringToVar(tracef_str, cstr, snprintf(cstr, size, __VA_ARGS__));\
	AS3_Trace(tracef_str);\
}
#endif
