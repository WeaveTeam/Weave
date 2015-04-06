#include "strftime2.h"
#include "strptime2.h"
#include <stdio.h>
#include <string.h>

void print_ext_tm(struct ext_tm *tm)
{
    printf(
"struct ext_tm tm = {\n"
"   .tm = {\n"
"       .tm_sec   = %d,\n"
"       .tm_min   = %d,\n"
"       .tm_hour  = %d,\n"
"       .tm_mday  = %d,\n"
"       .tm_mon   = %d,\n"
"       .tm_year  = %d,\n"
"       .tm_wday  = %d,\n"
"       .tm_yday  = %d,\n"
"       .tm_isdst = %d,\n"
"       .tm_gmtoff = %ld,\n"
"       .tm_zone   = %p,\n"
"   },\n"
"   .tm_msec = %d\n"
"}\n",
    tm->tm.tm_sec,
    tm->tm.tm_min,
    tm->tm.tm_hour,
    tm->tm.tm_mday,
    tm->tm.tm_mon,
    tm->tm.tm_year,
    tm->tm.tm_wday,
    tm->tm.tm_yday,
    tm->tm.tm_isdst,
    tm->tm.tm_gmtoff,
    tm->tm.tm_zone,
    tm->tm_msec
    );
}
int main(int argc, char* argv[])
{
    if (argc < 3)
    {
        fprintf(stderr, "Needs more arguments.\n");
        return 0;
    }
    
    char* format = argv[1];
    char* input = argv[2];
    char output[255];
    size_t result = 0;
    char* p_result = NULL;

    struct ext_tm tm;
    memset(&tm, 0, sizeof(tm));
    p_result = strptime2(input, format, &tm);
    printf("\"%s\" = strptime2(\"%s\", \"%s\", ...);\n", p_result || "NULL", input, format);
    print_ext_tm(&tm); 
    result = strftime2(output, 255, format, &tm);
    printf("%d = strftime2(\"%s\", \"%s\", ...);\n", result, input, format);
    printf("%s\n", output);
    return 0;
}
