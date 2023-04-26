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
