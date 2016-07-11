/* File utilities
   (c) Reuben Thomas 2000
*/


#ifndef MITE_FLEN
#define MITE_FLEN

#include "config.h"

#include <stdio.h>

#include "types.h"


long
flen (FILE *fp);

long
readFile (const char *file, Byte **data);

void
writeFile (const char *file, Byte *data, long len);

#endif
