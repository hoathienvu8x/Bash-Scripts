---
title: "Replace using POSIX regular expressions"
link: "https://www.daniweb.com/programming/software-development/code/216955/replace-using-posix-regular-expressions"
author: "TkTkorrovi"
publish: "Jul 9th, 2007 1:45 am"
---

Replaces every occasion of the pattern, or only the first occasion if there
is a subexpression, between `\(` and `\)`, anywhere in the regular expression,
as repeated replace is not what one would expect in that case. The string
size is restricted in POSIX regular expressions to the size of the int,
approximately 32 kbytes, but otherwise such replace should be enough for
anything necessary in real life.

```c
/* replace using posix regular expressions */
#include <stdio.h>
#include <string.h>
#include <regex.h>

int rreplace (char *buf, int size, regex_t *re, char *rp)
{
    char *pos;
    int sub, so, n;
    regmatch_t pmatch [10]; /* regoff_t is int so size is int */

    if (regexec (re, buf, 10, pmatch, 0)) return 0;
    for (pos = rp; *pos; pos++)
        if (*pos == '\\' && *(pos + 1) > '0' && *(pos + 1) <= '9') {
            so = pmatch [*(pos + 1) - 48].rm_so;
            n = pmatch [*(pos + 1) - 48].rm_eo - so;
            if (so < 0 || strlen (rp) + n - 1 > size) return 1;
            memmove (pos + n, pos + 2, strlen (pos) - 1);
            memmove (pos, buf + so, n);
            pos = pos + n - 2;
        }
    sub = pmatch [1].rm_so; /* no repeated replace when sub >= 0 */
    for (pos = buf; !regexec (re, pos, 1, pmatch, 0); ) {
        n = pmatch [0].rm_eo - pmatch [0].rm_so;
        pos += pmatch [0].rm_so;
        if (strlen (buf) - n + strlen (rp) + 1 > size) return 1;
        memmove (pos + strlen (rp), pos + n, strlen (pos) - n + 1);
        memmove (pos, rp, strlen (rp));
        pos += strlen (rp);
        if (sub >= 0) break;
    }
    return 0;
}

int main (int argc, char **argv)
{
    char buf [FILENAME_MAX], rp [FILENAME_MAX];
    regex_t re;

    if (argc < 2) return 1;
    if (regcomp (&re, argv [1], REG_ICASE)) goto err;
    for (; fgets (buf, FILENAME_MAX, stdin); printf ("%s", buf))
        if (rreplace (buf, FILENAME_MAX, &re, strcpy (rp, argv [2])))
            goto err;
    regfree (&re);
    return 0;
err:    regfree (&re);
    return 1;
}
```

I've taken the post by @marnout and fixed it up addressing a number of bugs
and typos. Fixes:memory leaks, infinite replacement if replacement contains
pattern, printing in function replaced with return values, back reference
values actually up to 31, documentation, more test examples.

```c
/* regex_replace.c
:w | !gcc % -o .%<
:w | !gcc % -o .%< && ./.%<
:w | !gcc % -o .%< && valgrind -v ./.%<
*/
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <regex.h>

int regex_replace(char **str, const char *pattern, const char *replace) {
    // replaces regex in pattern with replacement observing capture groups
    // *str MUST be free-able, i.e. obtained by strdup, malloc, ...
    // back references are indicated by char codes 1-31 and none of those
    // chars can be used in the replacement string such as a tab.
    // will not search for matches within replaced text, this will begin
    // searching for the next match after the end of prev match
    // returns:
    //   -1 if pattern cannot be compiled
    //   -2 if count of back references and capture groups don't match
    //   otherwise returns number of matches that were found and replaced
    //
    regex_t reg;
    unsigned int replacements = 0;
    // if regex can't commpile pattern, do nothing
    if(!regcomp(&reg, pattern, REG_EXTENDED)) {
        size_t nmatch = reg.re_nsub;
        regmatch_t m[nmatch + 1];
        const char *rpl, *p;
        // count back references in replace
        int br = 0;
        p = replace;
        while(1) {
            while(*++p > 31);
            if(*p) br++;
            else break;
        } // if br is not equal to nmatch, leave
        if(br != nmatch) {
            regfree(&reg);
            return -2;
        }
        // look for matches and replace
        char *new;
        char *search_start = *str;
        while(!regexec(&reg, search_start, nmatch + 1, m, REG_NOTBOL)) {
            // make enough room
            new = (char *)malloc(strlen(*str) + strlen(replace));
            if(!new) exit(EXIT_FAILURE);
            *new = '\0';
            strncat(new, *str, search_start - *str);
            p = rpl = replace;
            int c;
            strncat(new, search_start, m[0].rm_so); // test before pattern
            for(int k=0; k<nmatch; k++) {
                while(*++p > 31); // skip printable char
                c = *p;  // back reference (e.g. \1, \2, ...)
                strncat(new, rpl, p - rpl); // add head of rpl
                // concat match
                strncat(new, search_start + m[c].rm_so, m[c].rm_eo - m[c].rm_so);
                rpl = p++; // skip back reference, next match
            }
            strcat(new, p ); // trailing of rpl
            unsigned int new_start_offset = strlen(new);
            strcat(new, search_start + m[0].rm_eo); // trailing text in *str
            free(*str);
            *str = (char *)malloc(strlen(new)+1);
            strcpy(*str,new);
            search_start = *str + new_start_offset;
            free(new);
            replacements++;
        }
        regfree(&reg);
        // ajust size
        *str = (char *)realloc(*str, strlen(*str) + 1);
        return replacements;
    } else {
        return -1;
    }
}

const char test1[] = "before [link->address] some text [link2->addr2] trail[a->[b->c]]";
const char *pattern1 = "\\[([^-]+)->([^]]+)\\]";
const char replace1[] = "<a href=\"\2\">\1</a>";

const char test2[] = "abcabcdefghijklmnopqurstuvwxyzabc";
const char *pattern2 = "abc";
const char replace2[] = "!abc";

const char test3[] = "a1a1a1a2ba1";
const char *pattern3 = "a";
const char replace3[] = "aa";
int main(int argc, char *argv[])
{
    char *str1 = (char *)malloc(strlen(test1)+1);
    strcpy(str1,test1);
    puts(str1);
    printf("test 1 Before: [%s], ",str1);
    unsigned int repl_count1 = regex_replace(&str1, pattern1, replace1);
    printf("After replacing %d matches: [%s]\n",repl_count1,str1);
    free(str1);

    char *str2 = (char *)malloc(strlen(test2)+1);
    strcpy(str2,test2);
    puts(str2);
    printf("test 2 Before: [%s], ",str2);
    unsigned int repl_count2 = regex_replace(&str2, pattern2, replace2);
    printf("After replacing %d matches: [%s]\n",repl_count2,str2);
    free(str2);

    char *str3 = (char *)malloc(strlen(test3)+1);
    strcpy(str3,test3);
    puts(str3);
    printf("test 3 Before: [%s], ",str3);
    unsigned int repl_count3 = regex_replace(&str3, pattern3, replace3);
    printf("After replacing %d matches: [%s]\n",repl_count3,str3);
    free(str3);
}
```

[#66648777](https://stackoverflow.com/a/66648777)
