/* Mite translator shared utility routines
   (c) Reuben Thomas 2000
*/


#include <ctype.h>

#include "translate.h"


/* find the number of 1s in a 7-bit number using octal accumulators
   (no. of ones in a 3-bit no. is n - floor(n/2) - floor(n/4)) */
static int
countBits(int n)
{
  int n2, m = 033; /* mask */
  n -= (n2 = (n >> 1) & m);  /* n - floor(n/2) */
  n -= (n2 = (n2 >> 1) & m); /* n - floor(n/2) - floor(n/4) */
  return ((n + (n >> 3)) & 0x7) + (n >> 6);
    /* add 3-bit sub-totals and 7th bit */
}

/* Store w in the rest of the current instruction word in big-endian
   order; the data given in w must fit in p mod WORD_BYTE bytes */
static void
writeBytes(Byte *p, Word w)
{
  int i = WORD_BYTES_LEFT(p) - 1;
  do {
    p[i--] = (Byte)w; /* TODO: Check this cast works as expected */
    w >>= BYTE_BIT;
  } while (i >= 0);
}

/* Write an integer: sgn is 0 for +ve, 1 for -ve; n is the value */
static Word
writeInt(Byte *p, int sgn, Word n)
{
  int len = 1, cur = (WORD_BYTES_LEFT(p) << BYTE_SHIFT) - 1;
  Word bytes = 0;
  while (n >> len && len < (int)WORD_BIT)
    len++;
  if (sgn)
    n = (Word)(-(SWord)n);
  while ((bytes += (cur + 1) >> BYTE_SHIFT), len > cur) {
    len -= cur; /* Number of bits left */
    writeBytes(p, (Word)(n >> len));
    cur = WORD_BIT - 1;
  }
  writeBytes(p, (Word)(n & ((1 << cur) - 1)) /* Mask cur bits */
	     | (1 << cur)); /* Add 1 bit to last word */
  return bytes;
}


static int
issym(int c)
{
  return isalnum(c) || (c == '_');
}

static int
isimm(int c)
{
  return isxdigit(c) || strchr(">-_swx", c);
}


static void
addDangle(TState *T, LabelType ty, LabelValue v, ptrdiff_t off)
{
  Dangle *d = new(Dangle);
  Label *l = new(Label);
  l->ty = ty;
  l->v = v;
  d->l = l;
  d->off = off;
  T->dangleEnd->next = d;
  T->dangleEnd = d;
}

static TState *
translatorNew(void)
{
  TState *T = new(TState);
  T->dangles = new(Dangle);
  T->dangles->next = NULL;
  T->dangleEnd = T->dangles;
  return T;
}  
