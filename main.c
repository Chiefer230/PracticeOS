#include "stdint.h"
#include "stddef.h"

void Kmain(void)
{
    char * pointer = (char*) 0xb8000;
    pointer[0] = 'C';
    pointer[1] = 0xa;
}