/* Exception handling
   (c) Reuben Thomas 1997
*/


#ifndef MITE_EXCEPT
#define MITE_EXCEPT

#include "config.h"

#include <stdlib.h>
#include <stdarg.h>
#include <setjmp.h>


void warn (int exc, ...);
void die (int exc, ...);

void *excMalloc (size_t size);
void *excCalloc (size_t nobj, size_t size);
void *excRealloc (void *p, size_t size);

#define new(T) excMalloc (sizeof (T))

extern unsigned long excPos;
extern char *excFile;
extern char *progName;

typedef enum {
#include "excEnum.h"
} Exception;

#endif
