/* Mite translator shared utility routines
   (c) Reuben Thomas 2000
*/


#include <ctype.h>

#include "translate.h"


static void
addDangle (TState *T, LabelType ty, LabelValue v, ptrdiff_t off)
{
  Dangle *d = new (Dangle);
  Label *l = new (Label);
  l->ty = ty;
  l->v = v;
  d->l = l;
  d->off = off;
  T->dangleEnd->next = d;
  T->dangleEnd = d;
}

static TState *
translatorNew (void)
{
  TState *T = new (TState);
  T->dangles = new (Dangle);
  T->dangles->next = NULL;
  T->dangleEnd = T->dangles;
  return T;
}  
