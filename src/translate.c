/* Mite abstract grammar
   (c) Reuben Thomas 2000
*/


#include <string.h>

#include "except.h"
#include "buffer.h"
#include "translate.h"


/* Instructions' operand types */
#define OPS(t1, t2, t3)  ((op_ ## t3) << 8) | ((op_ ## t2) << 4) | (op_ ## t1)
unsigned int opType[] = {
#include "opToTypes.c"
};

const char *labelType[] = {
  "branch",
  "subroutine",
  "data"
};

void
align(TState *t)
{
  unsigned int n;
  for (n = WORD_BYTES_LEFT(t->wPtr) & WORD_ALIGN; n; n--)
    *t->wPtr++ = (Byte)0;
}

void
addDangle(TState *t, unsigned int ty, LabelValue v)
{
  Dangle *d = new(Dangle);
  Label *l = new(Label);
  l->ty = ty;
  l->v = v;
  d->l = l;
  d->ins = t->wPtr - t->wImg;
  t->dangleEnd->next = d;
  t->dangleEnd = d;
}

void
resolveDangles(TState *t, Byte *finalImg, Byte *finalPtr,
              uintptr_t maxlen,
	      uintptr_t (*writeUInt)(Byte **p, uintptr_t n),
	      LabelValue (*labelMap)(TState *t, Label *l))
{
  Dangle *d;
  uintptr_t prev = 0, extras, n, off = finalPtr - finalImg;
  for (d = t->dangles->next, n = 0; d; d = d->next, n++);
  finalImg = excRealloc(finalImg, t->wPtr - t->wImg + n * maxlen + off);
  finalPtr = finalImg + off;
  for (d = t->dangles->next; d; d = d->next) {
    memcpy(finalPtr, t->wImg + prev, d->ins - prev);
    finalPtr += d->ins - prev;
    extras = writeUInt(&finalPtr, labelMap(t, d->l).n);
    prev = d->ins + extras;
  }
  memcpy(finalPtr, t->wImg + prev, t->wPtr - t->wImg - prev);
  finalPtr += t->wPtr - t->wImg - prev;
  free(t->wImg);
  t->wImg = realloc(finalImg, finalPtr - finalImg);
  t->wPtr = t->wImg + (finalPtr - finalImg);
}

TState *
translatorNew(Byte *img, Byte *end)
{
  TState *t = new(TState);
  t->rPtr = t->rImg = img;
  t->rEnd = end;
  t->wImg = bufNew(t->wSize, MIN_IMAGE_SIZE);
  t->wPtr = t->wImg;
  t->dangles = new(Dangle);
  t->dangleEnd = t->dangles;
  return t;
}  
