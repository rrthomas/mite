/* Find the length of a file
   (c) Reuben Thomas 2000
*/


#include <stdio.h>

#include "flen.h"

long
flen(FILE *fp)
{
  long pos = ftell(fp);
  if (pos != -1 && fseek(fp, 0, SEEK_END) == 0) {
    long len = ftell(fp);
    if (len != -1 && fseek(fp, pos, SEEK_SET) == 0)
      return len;
  }
  return -1;
}
