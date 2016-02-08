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

#include <stdlib.h>
#include <stdbool.h>
#include "AS3/AS3.h"
#include "tracef.h"
#include "uthash.h"


//package_as3(
//	"#package public\n"
//	"public var errorCode:int = 0;\n"
//);

size_t stringHashId = 0;

typedef struct entry_t {
	char *str;
	size_t id;
	UT_hash_handle hh;
} entry_t ;

size_t findstr_maxlen = 0;
char *findstr = NULL;
entry_t *entry_table = NULL;

inline bool isWhitespace(char c)
{
	switch (c)
	{
		case ' ':
		case '\t':
		case '\r':
		case '\n':
		case '\f':
			return true;
		default:
			return false;
	}
}

void stringHash() __attribute__((used,
	annotate("as3sig:public function stringHash(str:String, trim:Boolean = false):int"),
	annotate("as3package:weave.flascc")));
void stringHash()
{
	// expand buffer if necessary (max length of a utf-8 char is 6 bytes)
	size_t as3str_len;
	inline_nonreentrant_as3(
		"if (str == null)"
		"    return 0;"
		"%0 = str.length;"
		: "=r"(as3str_len)
	);
	if (findstr_maxlen < as3str_len * 6)
	{
		if (findstr)
			free(findstr);
		findstr_maxlen = as3str_len * 6;
		findstr = (char*)malloc(findstr_maxlen + 1);
	}

	// write string to buffer
	size_t pos;
	inline_nonreentrant_as3(
		"ram_init.position = %1;"
		"ram_init.writeUTFBytes(str);"
		"%0 = ram_init.position;"
		"ram_init.writeByte(0);"
		: "=r"(pos) : "r"(findstr)
	);
	size_t str_len = pos - (size_t)findstr;
	char* str = findstr;
	
	/* Strip leading whitespace */
	while (isWhitespace(*str))
	{
		str++;
		str_len--;
	}
	/* Strip trailing whitespace */
	while (str_len > 0 && isWhitespace(str[str_len - 1]))
		str_len--;
	str[str_len] = '\0';

	// find matching entry
	entry_t *entry;
	HASH_FIND(hh, entry_table, str, str_len, entry);
	if (!entry)
	{
		// no match, create entry
		entry = (entry_t*)malloc(sizeof(entry_t));
		entry->str = (char*)malloc(str_len + 1);
		strncpy(entry->str, str, str_len + 1);
		entry->id = ++stringHashId;
		HASH_ADD_KEYPTR(hh, entry_table, entry->str, str_len, entry);
	}
	AS3_Return(entry->id);
}
