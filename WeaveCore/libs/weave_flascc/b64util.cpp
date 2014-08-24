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
	inline_nonreentrant_as3("%0 = input.length;" : "=r"(input_len));
	input_ptr = (char*)malloc(input_len);
	inline_as3(
		"ram_init.position = %0;"
		"ram_init.writeBytes(input);"
			: : "r"(input_ptr)
	);

	size_t output_len = modp_b64_encode_len(input_len);
	char *output_ptr = (char*)malloc(input_len);

	AS3_DeclareVar(output, String);
	if (modp_b64_encode(output_ptr, input_ptr, input_len) != -1)
		AS3_CopyCStringToVar(output, output_ptr, output_len);

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
	size_t input_len;
	char *input_ptr;
	AS3_StringLength(input_len, input);
	AS3_MallocString(input_ptr, input);

	size_t output_len = modp_b64_decode_len(input_len);
	char *output_ptr = (char*)malloc(output_len);

	AS3_DeclareVar(output, ByteArray);
	int len = modp_b64_decode(output_ptr, input_ptr, input_len);
	if (len != 1)
		inline_as3(
			"output = new ByteArray();"
			"ram_init.position = %0;"
			"ram_init.readBytes(output, 0, %1);"
				 : : "r"(output_ptr), "r"(len)
		);

	free(input_ptr);
	free(output_ptr);
	AS3_ReturnAS3Var(output);
}

