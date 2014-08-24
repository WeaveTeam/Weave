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

#include "modp_b64.h"
#include <stdlib.h>
#include "AS3/AS3.h"
#include "tracef.h"

void btoa() __attribute__((used,
	annotate("as3sig:public function btoa(input:ByteArray):String"),
	annotate("as3package:weave.flascc"),
	annotate("as3import:flash.utils.ByteArray")));
void btoa()
{
	char *input_ptr;
	size_t input_len;
	AS3_GetScalarFromVar(input_len, input.length);
	input_ptr = (char*)malloc(input_len);
	inline_nonreentrant_as3(
		"ram_init.position = %0;"
		"ram_init.writeBytes(input);"
			: : "r"(input_ptr)
	);

	size_t output_len = modp_b64_encode_len(input_len);
	char *output_ptr = (char*)malloc(output_len);

	AS3_DeclareVar(output, String);
	int len = modp_b64_encode(output_ptr, input_ptr, input_len);
	if (len != -1)
		AS3_CopyCStringToVar(output, output_ptr, len);

	free(input_ptr);
	free(output_ptr);
	AS3_ReturnAS3Var(output);
}

void atob() __attribute__((used,
	annotate("as3sig:public function atob(input:String):ByteArray"),
	annotate("as3package:weave.flascc"),
	annotate("as3import:flash.utils.ByteArray")));
void atob()
{
	// copy input string to scratch buffer to get byte length
	size_t input_len;
	inline_nonreentrant_as3(
		"var output:ByteArray = new ByteArray();"
		"output.position = 0;"
		"output.writeUTFBytes(input);"
		"while (output.position %% 4)"
		"    output.writeUTFBytes('=');"
		"%0 = output.position;"
		: "=r"(input_len)
	);

	// allocate memory and copy from scratch buffer
	// also make sure scratch buffer doesn't stay too large
	char *input_ptr = (char*)malloc(input_len);
	inline_nonreentrant_as3(
		"ram_init.position = %0;"
		"ram_init.writeBytes(output, 0, %1);"
		: : "r"(input_ptr), "r"(input_len)
	);

	// allocate output buffer
	size_t output_len = modp_b64_decode_len(input_len);
	char *output_ptr = (char*)malloc(output_len);

	// decode input string and copy to scratch ByteArray
	int len = modp_b64_decode(output_ptr, input_ptr, input_len);
	if (len != -1)
		inline_nonreentrant_as3(
			"output.position = 0;"
			"ram_init.position = %0;"
			"ram_init.readBytes(output, 0, %1);"
			"output.length = %1;"
				 : : "r"(output_ptr), "r"(len)
		);
	else
		inline_nonreentrant_as3("output = null;");

	// free memory and return output
	free(input_ptr);
	free(output_ptr);
	AS3_ReturnAS3Var(output);
}

