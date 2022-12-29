---
title: "Resizing arrays in C"
link: "https://colinnewell.wordpress.com/2007/06/13/resizing-arrays-in-c/"
author: "The Dumping Ground"
pubdate: "2007-06-13T23:58:52+00:00"
---

It's not possible to resize arrays allocated on the stack. Well not in any
orthodox way. The only real way to do it is with stuff allocated on the heap.
You can use realloc or do it manually yourself and use `malloc`.

One useful thing that might make you think there were resizeable strings
though is being able to specify an array without specifying it's dimension.
The thing is that you do that while specifying it's contents. For example,

```c
char mystring[] = "hello";
```

That creates a string on the stack with enough memory for the "hello" string
and puts that into it.

That’s different to char `*mystring = "hello";` because you actually have memory
allocated on the stack for that first example. That means that unlike the `char *`
you can write to the memory.

Of course just because you've sized an array doesn’t mean it has to be that size.
A trick one of my friends came up with was creating a struct with a 1 char array
at the end. He would then cast that to a block of memory and use that as the way
to access the rest of the block of memory.

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct pascal_string
{
        int length;
        char c_str[1];
} pascal_string;

pascal_string *new_string(int length, char *value)
{
        pascal_string *str = (pascal_string*) malloc((sizeof(char)*length)+sizeof(struct pascal_string));
        // allocates one extra char so that it can store the null 
        // and have the string both C style and Pascal style.
        str->length = length;
        memcpy(str->c_str, value, length*sizeof(char));
        str->c_str[length] = '';
        return str;
}

void main()
{
        char test[3] = { 'a', 'b', 'c' };
        pascal_string *str;

        str = new_string(3, test);
        printf("%d : %s\n", str->length, str->c_str);
}
```

This is a really contrived example but as you can see you can overlay the struct
over the memory and it allows you to make the most of the compiler. You don't need
to have a `char *` that you need to set to be a pointer to the memory. References
to the array will already be pointing to the correct place.

The reason he liked it so much is that he was able to load chunks of files and
overlay that struct to allow him to manage whole chunks at a time in a single
block of memory.
