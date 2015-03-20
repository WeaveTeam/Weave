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
#include <string.h>
#include <time.h>
#include "AS3/AS3.h"
#include "tracef.h"

#define DATE_FORMAT_MAX (1024)
void date_format() __attribute((used,
            annotate("as3sig:public function date_format(date:Date, fmt:String):String"),
            annotate("as3package:weave.flascc")));

void date_format()
{
    char *fmt;

    struct tm tm;
    memset(&tm, 0, sizeof(struct tm));
    
    inline_as3(
        "var output:String = null;"
        "%0 = CModule.mallocString(fmt);"
        "%1 = date.fullYear - 1900;"
        "%2 = date.month;"
        "%3 = date.date;"
        "%4 = date.hours;"
        "%5 = date.minutes;"
        "%6 = date.seconds;"
        : 
        "=r"(fmt), 
        "=r"(tm.tm_year),
        "=r"(tm.tm_mon),
        "=r"(tm.tm_mday),
        "=r"(tm.tm_hour),
        "=r"(tm.tm_min),
        "=r"(tm.tm_sec)
    );

    char* output = (char*)malloc(sizeof(char)*DATE_FORMAT_MAX);
    size_t output_len;

    if (strftime(output, DATE_FORMAT_MAX, fmt, &tm))
    {
        output_len = strnlen(output, DATE_FORMAT_MAX);
        inline_as3(
                "ram.position = %0;"
                "output = ram.readUTFBytes(%1);"
                : : "r"(output), "r"(output_len)
        );
    }

    free(fmt);
    free(output);

    AS3_ReturnAS3Var(output);
}

void date_parse() __attribute((used,
            annotate("as3sig:public function date_parse(date:String, fmt:String, utc:Boolean = false):Date"),
            annotate("as3package:weave.flascc")));

void date_parse()
{
    char *date_str;
    char *fmt;
    inline_as3(
        "if (!date)"
        "	return null;"
        "var output:Date = null;"
        "%0 = CModule.mallocString(date + '%%');"
        "%1 = CModule.mallocString(fmt + '%%');"
        : "=r"(date_str), "=r"(fmt)
    );

    struct tm tm;
    memset(&tm, 0, sizeof(struct tm));
    tm.tm_mday = 1;

    if (strptime(date_str, fmt, &tm) == date_str + strlen(date_str))
    {
		inline_nonreentrant_as3(
			"if (utc)"
			"    output = new Date(Date.UTC(%0,%1,%2,%3,%4,%5));"
			"else"
			"    output = new Date(%0,%1,%2,%3,%4,%5);"
			: : "r"(tm.tm_year + 1900),
			 "r"(tm.tm_mon),
			 "r"(tm.tm_mday),
			 "r"(tm.tm_hour),
			 "r"(tm.tm_min),
			 "r"(tm.tm_sec)
		);
    }

    free(date_str);
    free(fmt);

    AS3_ReturnAS3Var(output);
}


size_t dates_detect_c(char* dates[], size_t dates_n, char* formats[], size_t* formats_n);

void dates_detect() __attribute((used,
            annotate("as3sig:public function dates_detect(dates:*, formats:Array):Array"),
            annotate("as3package:weave.flascc")));

void dates_detect()
{
    size_t dates_n;
    size_t formats_n;
    AS3_GetScalarFromVar(dates_n, dates.length);
    AS3_GetScalarFromVar(formats_n, formats.length);

    char* dates[dates_n];
    char* formats[formats_n];

    size_t idx;
    char* tmp;

    for (idx = 0; idx < dates_n; idx++)
    {
        inline_as3(
                "var date:String = dates[%1] as String;"
                "%0 = date ? CModule.mallocString(date + '%%') : 0;"
                : "=r"(tmp) : "r"(idx)
        );
        dates[idx] = tmp;
    }

    for (idx = 0; idx < formats_n; idx++)
    {
        inline_as3(
                "var fmt:String = formats[%1] as String || '';"
                "%0 = CModule.mallocString(fmt + '%%');"
                : "=r"(tmp) : "r"(idx)
        );
        formats[idx] = tmp;
    }

    dates_detect_c(dates, dates_n, formats, &formats_n);

    /* Free the dates */
    for (idx = 0; idx < dates_n; idx++)
        free(dates[idx]);

    inline_nonreentrant_as3(
            "var output:Array = new Array(%0)"
            : : "r"(formats_n)
    );

    size_t len;
    for (idx = 0; idx < formats_n; idx++)
    {
        len = strlen(formats[idx]) - 1; // subtract 1 to account for added '%'
        inline_as3(
                "ram.position = %0;"
                "var formatStr:String = ram.readUTFBytes(%1);"
                "output[%2] = formatStr;"
                : : "r"(formats[idx]), "r"(len), "r"(idx)
        );
        free(formats[idx]);
    }
    AS3_ReturnAS3Var(output);
}

/**
 * Filter a list of date format strings down to only those which return a valid result for all dates.
 * @param dates An array of date strings to test against.
 * @param dates_n The length of dates.
 * @param formats The array of candidate format strings. This will be altered
 *                to only contain format strings which work for all dates provided.
 * @param formats_n A pointer to the length of the candidate format string list. This will be altered to match the length of the filtered output.
 * @return The number of formats which were valid for all input strings.
 */

size_t dates_detect_c(char* dates[], size_t dates_n, char* formats[], size_t *formats_n)
{
    /* fmt_idx needs to be int so we can let it go negative */
    int row_idx, fmt_idx;
    size_t formats_remaining = *formats_n;
    struct tm tmp_time;
    for (row_idx = 0; row_idx < dates_n; row_idx++)
    {
        if (dates[row_idx] == NULL)
        	continue;
        for (fmt_idx = 0; fmt_idx < formats_remaining; fmt_idx++)
        {
            if (formats[fmt_idx] == NULL)
            {
                formats_remaining = fmt_idx+1;
                break;
            }
            //tracef("strptime(%s, %s, ...)\n", dates[row_idx], formats[fmt_idx]);
            if (strptime(dates[row_idx], formats[fmt_idx], &tmp_time) == NULL)
            {
                /*
                 * Put the last entry in this slot, make the last entry NULL,
                 * and reduce the length to test. Decrementing fmt_idx ensures
                 * that we test the entry that is now at this slot on the next pass.
                 */
                formats_remaining--;
                free(formats[fmt_idx]);
                formats[fmt_idx] = formats[formats_remaining];
                formats[formats_remaining] = NULL;
                fmt_idx--;
            }
        }
    }
    return *formats_n = formats_remaining;
}
