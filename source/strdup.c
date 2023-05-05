// https://engineering.purdue.edu/ece264/21sp/lecture/20210302/snippets/strdup.c
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <assert.h>

char* strdup(const char* src) {
// Make a copy of the src string.

    // Find the LENGTH including the '\0'.
    int num_bytes = 0;
    while(src[num_bytes] != '\0') {
        num_bytes += 1;
    }
    num_bytes += 1;  // for the '\0'

    // ALLOCATE memory for the copy.
    char* copy_of_src = malloc(num_bytes * sizeof(*copy_of_src));
    //                                            ▲  Do not forget the ASTERISK.

    // COPY the bytes in src.
    for(int i = 0; i < num_bytes; i++) {
        copy_of_src[i] = src[i];
    }

    return copy_of_src;
}

int main(int argc, char* argv[]) {
    char* dog_name = "Cat";  // No need to free this.  It is on the data segment.
    printf("dog_name         == %s\n\n", dog_name);

    char* copy_of_dog_name = strdup(dog_name);   // <<<<<< strdup(…) is called here <<<<<<
    printf("copy_of_dog_name == %s\n", copy_of_dog_name);

    free(copy_of_dog_name);  // <<<<< DON'T FORGET!!!

    return EXIT_SUCCESS;
}
/* vim: set tabstop=4 shiftwidth=4 fileencoding=utf-8 noexpandtab: */
