/* Mite translator shared utility routines
   (c) Reuben Thomas 2000
*/


#include <string.h>

#include "except.h"
#include "buffer.h"
#include "translate.h"


void
align(TState *t)
{
  unsigned int n;
  for (n = WORD_BYTES_LEFT(t->wPtr) & WORD_ALIGN; n; n--)
    *t->wPtr++ = (Byte)0;
}

void
addDangle(TState *t, LabelType ty, LabelValue v)
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
