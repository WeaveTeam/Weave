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

#include "CSVParser.h"

const char CR = '\r';
const char LF  = '\n';

CSVParser::CSVParser(char delimiter, char quote, bool removeBlankLines, bool parseTokens)
	: delimiter(delimiter), quote(quote), removeBlankLines(removeBlankLines), parseTokens(parseTokens)
{
}

CSVParser::~CSVParser()
{
}

/**
 * @param input Either a ByteArray or a String
 * @param delimiter
 * @param quote
 * @param removeBlankLines
 * @param parseTokens
 */
void parseCSV() __attribute__((used,
		annotate("as3sig:public function parseCSV(input:*, delimiter:String = ',', quote:String = '\"', removeBlankLines:Boolean = true, parseTokens:Boolean = true, output:Array = null):Array"),
		annotate("as3package:weave.utils"),
		annotate("as3import:flash.utils.ByteArray")));

void parseCSV()
{
	char *str;
	char delim, quot;
	bool rem, parse;

	// read params and initialize
	inline_as3(
		"if (output)"
		"    output.length = 0;"
		"else"
		"    output = [];"
		"if (input === undefined || input === null || input === '')"
		"    return output;" // no rows
		"if (input is ByteArray)"
		"{"
		"    var ptr:int = CModule.malloc(input.length + 1);"
		"    ram.position = ptr;"
		"    ram.writeBytes(input);"
		"    ram.writeByte(0);"
		"    %0 = ptr;"
		"}"
		"else"
		"{"
		"    %0 = CModule.mallocString(String(input));"
		"}"
		"%1 = delimiter.charCodeAt(0);"
		"%2 = quote.charCodeAt(0);"
		"%3 = removeBlankLines;"
		"%4 = parseTokens;"
		"var outputCol:int = 0;"
		"var outputRow:Array = [];"
		"output[0] = outputRow;"
		: "=r"(str), "=r"(delim), "=r"(quot), "=r"(rem), "=r"(parse)
	);

	CSVParser parser(delim, quot, rem, parse);
	parser.parse(str);
	free(str);

	AS3_ReturnAS3Var(output);
}

// moves to the next row in the output
inline void CSVParser::newRow()
{
	// if skipping blank rows, don't create a new row if current row is blank
	inline_nonreentrant_as3(
		"outputRow.length = outputCol;"
		"if (!(%0 && outputCol == 1 && outputRow[0] == ''))"
		"    output.push(outputRow = new Array(outputRow.length));"
		"outputCol = 0;"
		: : "r"(removeBlankLines)
	);
}

// push new token onto output array
inline void CSVParser::saveToken(char* start, char* end)
{
	// if there are at least two characters and the token is surrounded with quotes, parse the token in-place
	if (parseTokens && end - start >= 2 && *start == quote && *(end - 1) == quote)
	{
		// remove surrounding quotes
		char* pos = ++start;
		--end;
		// unescape escaped quotes by modifying the string in-place
		size_t offset = 0;
		while (++pos < end)
		{
			if (*pos == quote)
				++pos, ++offset;
			if (offset != 0)
				*(pos - offset) = *pos;
		}
		end -= offset;
	}

	inline_as3(
		"ram.position = %0;"
		"var token:String = ram.readUTFBytes(%1);"
		"outputRow[outputCol] = token;"
		"++outputCol;"
		: : "r"(start), "r"(end - start)
	);
}

//TODO handle this case:   'a,b\n""\nc,d' (second row should not be removed)
inline void CSVParser::parse(char* csvInput)
{
	// special case -- if csv is empty, do nothing
	if (!*csvInput)
		return;

	bool escaped = false;

	char* start = csvInput;

	char chr;
	char *next = csvInput;
	while (chr = *next++)
	{
		if (escaped)
		{
			if (chr == quote)
			{
				if (*next == quote) // escaped quote
				{
					// skip second quote mark
					++next;
				}
				else // end of escaped text
				{
					escaped = false;
				}
			}
		}
		else
		{
			if (chr == delimiter)
			{
				// end of current token
				saveToken(start, next - 1);
				start = next; // new token begins after delimiter
			}
			else if (chr == quote)
			{
				// is the quote at the beginning of the token?
				if (next - 1 == start)
					escaped = true;
			}
			else if (chr == LF)
			{
				// end of current token and current row
				saveToken(start, next - 1);
				start = next; // new token begins after LF
				newRow();
			}
			else if (chr == CR)
			{
				// end of current token and current row
				saveToken(start, next - 1);

				// handle CRLF
				if (*next == LF)
					start = ++next; // new token begins after CRLF
				else
					start = next; // new token begins after CR
				newRow();
			}
		}
	}

	saveToken(start, next - 1);

	// if we have more than one line, remove last line if it's blank (trailing newline character)
	inline_nonreentrant_as3(
		"outputRow.length = outputCol;"
		"if (output.length > 1 && outputCol == 1 && outputRow[0] == '') output.pop();"
	);
}
