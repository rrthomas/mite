-- Mite object reader
-- (c) Reuben Thomas 2000


return Reader(
  "Mite object code",
  [[
/* Need a post-pass to verify everything else (what is there?) */

     
#include <stdint.h>
#include <limits.h>

#include "translate.h"


/* set excLine to the current offset into the image, then throw an
   exception */ 
static void
throwPos(TState *t, int exc, ...)
{
  va_list ap;
  va_start(ap, exc);
  excLine = t->rPtr - t->rImg;
  vThrow(exc, ap);
  va_end(ap);
}

/* find the number of 1s in a 7-bit number using octal accumulators
   (no. of ones in a 3-bit no. is n - floor(n/2) - floor(n/4)) */
static int
bits(int n)
{
  int n2, m = 033; /* mask */
  n -= (n2 = (n >> 1) & m);  /* n - floor(n/2) */
  n -= (n2 = (n2 >> 1) & m); /* n - floor(n/2) - floor(n/4) */
  return ((n + (n >> 3)) & 0x7) + (n >> 6);
    /* add 3-bit sub-totals and 7th bit */
}

static Word
getBits(TState *t, Word n)
{
#define p t->rPtr
  int i, endBit, bits;
  Word w;
  if (p < t->rEnd) {
    do {
      w = 0;
      bits = -1;
      i = WORD_BYTES_LEFT(p);
      endBit = *p & (1 << (BYTE_BIT - 1));
      do {
	w = (w << BYTE_BIT) | *p++;
	bits += BYTE_BIT;
	i--;
      } while (i);
      n = (n << (WORD_BIT - 1)) + w;
    } while (endBit == 0 && p < t->rEnd);
    n -= 1 << bits;
  }
  if (endBit == 0 && p == t->rEnd)
    throwPos(t, ExcBadImm);
  return n;
#undef p
}

static Word
getNum(TState *t, int *sgnRet)
{
#define p t->rPtr
  Byte *start = p;
  Word h = *p & (BYTE_SIGN_BIT - 1);
  Word n;
  int sgn;
  unsigned int len;
  sgn = -(h >> (BYTE_BIT - 2));
  n = getBits(t, (Word)sgn);
  len = (unsigned int)(p - start - 1); /* Don't count first byte,
                                          which is in h */
  if ((BYTE_BIT - 1) * len +
      bits((int)(sgn == 0 ? h : ~h & (BYTE_SIGN_BIT - 1)))
      > WORD_BIT + sgn)
    throwPos(t, ExcBadImmVal);
      /* (BYTE_BIT - 1) * len is the no. of significant bits in the
         bottom bytes bits(...) is the number in the most significant
         byte if we're reading a negative number, the maximum size is
         one less */
  *sgnRet = sgn;
  return sgn ? (Word)(-(SWord)n) : n;
#undef p
}

#ifdef LITTLE_ENDIAN

#  define OPCODE(w) \
     (w) & BYTE_MASK
#  define OP(p) \
     (w >> (BYTE_BIT * (p))) & BYTE_MASK

#else /* !LITTLE_ENDIAN */

#  define OPCODE(w) \
     (w >> (BYTE_BIT * 3)) & BYTE_MASK
#  define OP(p) \
     (w >> (BYTE_BIT * (WORD_BYTE - (p)))) & BYTE_MASK

#endif /* LITTLE_ENDIAN */

#define labelAddr(t, l) l->v
]],
  {
    r = OpType([[#undef r%n
        #define r%n op%n]],
        [[if (r%n == 0) /* r%n can't be > UINT_MAX */
          throwPos(t, ExcBadReg);]]),
    i = OpType([[#undef i%n_f
        #define i%n_f op%n
        int i%n_sgn;
        Word i%n_v;
        int i%n_r;]],
               function (inst, op)
                 return
        [[if (i%n_f & ~(FLAG_R | FLAG_S | FLAG_W | FLAG_E))
          throwPos(t, ExcBadImmMod);
        i%n_r = (op%n & FLAG_R) ?
          (t->rPtr -= 2 - %n, op]] .. tostring(op + 1) .. [[) :
          ((t->rPtr -= 3 - %n), 0);
        i%n_v = getNum(t, &i%n_sgn);]]
               end),
    t = OpType([[#undef t%n
        #define t%n op%n]],
        [[if (op%n == 0 || op%n > LABEL_TYPES)
          throwPos(t, ExcBadLabTy);]]),
    l = OpType([[int l%n_sgn;
        LabelValue l%n;]],
               function (inst, op)
                 return [[t->rPtr -= 4 - %n;
        l%n.n = getNum(t, &l%n_sgn);
        if (l%n_sgn)
          throwPos(t, ExcBadLab);]]
               end),
    n = OpType("LabelValue l%n;",
               function (inst, op)
                 return "l%n.n = ++t->labels[t" .. tostring(op - 1) ..
                   "];"
               end),
  },
  Translator(
    [[InstWord w;
    Byte op1, op2, op3;]],   -- decls
    [[t->labHash = hashNew(4096);
    t->eol = 0;]],           -- init
    [[w = *(InstWord *)t->rPtr;
    op1 = OP(1);
    op2 = OP(2);
    op3 = OP(3);
    o = OPCODE(w);
    t->rPtr += WORD_BYTE;]], -- update
    ""                       -- finish
  )
)
