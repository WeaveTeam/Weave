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

#ifndef CSVPARSER_H_
#define CSVPARSER_H_

#include <stdlib.h>
#include "AS3/AS3.h"
#include "tracef.h"

using namespace std;

class CSVParser
{
private:
	char delimiter;
	char quote;
	bool removeBlankLines;
	bool parseTokens;

	inline void newRow();
	inline void saveToken(char* start, char* end);

public:
	inline void parse(char*);

	CSVParser(char delimiter, char quote, bool removeBlankLines, bool parseTokens);
	~CSVParser();
};

#endif /* CSVPARSER_H_ */
