/* Auto-extending buffers
   (c) Reuben Thomas 2000
*/


#ifndef MITE_BUFFER
#define MITE_BUFFER


#include "except.h"

#define bufNew(size, init) excMalloc(((size)= (init)))
#define bufExt(buf, size, need) \
  if ((size) < (need)) \
    (buf)= excRealloc((buf), (size)= max((size) * 2, (need)))
#define bufShrink(buf, used) excRealloc((buf), (used))
#define bufEnsure(n) \
  bufExt(t->wImg, t->wSize, (uintptr_t)(t->wPtr - t->wImg + (n)))

#endif
