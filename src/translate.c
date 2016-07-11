/* Mite translator shared utility routines
   (c) Reuben Thomas 2000
*/


#include "config.h"

#include <ctype.h>
#include <math.h>

#include "translate.h"


static char
labTyToChar (LabelType ty)
{
  switch (ty) {
  case LABEL_B:
    return 'b';
  case LABEL_S:
    return 's';
  case LABEL_D:
    return 'd';
  case LABEL_F:
    return 'f';
  }
}

static Word
writeNum (char *s, Word n)
{
  Word last = n ? (Word)(log10 (n)) : 0;
  s += last;
  do {
    *s-- = '0' + n % 10;
    n /= 10;
  } while (n);
  return last + 1;
}

static ptrdiff_t
writeImm (char *s, int f, int n, Word v, Word r)
{
  char *t = s;
  if (f & FLAG_E)
    *t++ = 'e';
  if (f & FLAG_S)
    *t++ = 's';
  if (f & FLAG_W)
    *t++ = 'w';
  if (n)
    *t++ = '-';
  t += writeNum (t, v);
  if (r) {
    *t++ = '>';
    *t++ = '>';
    t += writeNum (t, r);
  }
  return t - s;
}

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

static void
debug (const char *fmt, ...)
{
  va_list ap;
  va_start (ap, fmt);
  vfprintf (stderr, fmt, ap);
  va_end (ap);
}
