-- Mite object reader
-- (c) Reuben Thomas 2000


return Reader{
  "Mite object code",
  "typedef interpW_Output objR_Input;",
  [[
#include <stdint.h>
#include <limits.h>

/* TODO: Need a post-pass to verify everything else (what is there?) */


/* Object reader state */
typedef struct {
  Byte *img, *end, *ptr;
} objR_State;

/* set excPos to the current offset into the image, then throw an
   exception */ 
static void
throwPos(objR_State *R, int exc)
{
  excPos = R->ptr - R->img;
  throw(exc);
}

static Word
objR_getBits(objR_State *R, Word n)
{
#define p R->ptr
  int i, endBit, bits;
  Word w;
  if (p < R->end) {
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
    } while (endBit == 0 && p < R->end);
    n -= 1 << bits;
  }
  if (endBit == 0 && p == R->end)
    throwPos(R, ExcBadImm);
  return n;
#undef p
}

static Word
objR_getNum(objR_State *R, int *sgnRet)
{
#define p R->ptr
  Byte *start = p;
  Word h = *p & (BYTE_SIGN_BIT - 1);
  int sgn = -(h >> (BYTE_BIT - 2));
  Word n = objR_getBits(R, (Word)sgn);
  unsigned int len = (unsigned int)(p - start - 1);
    /* Don't count first byte, which is in h */
  if ((BYTE_BIT - 1) * len +
      countBits((int)(sgn == 0 ? h : ~h & (BYTE_SIGN_BIT - 1)))
      > WORD_BIT + sgn)
    throwPos(R, ExcBadImmVal);
      /* (BYTE_BIT - 1) * len is the no. of significant bits in the
         bottom bytes countBits(...) is the number in the most
         significant byte if we're reading a negative number, the
         maximum size is one less */
  *sgnRet = sgn;
  return sgn ? (Word)(-(SWord)n) : n;
#undef p
}

#ifdef LITTLE_ENDIAN

#  define objR_OPCODE \
     (objR_w) & BYTE_MASK
#  define objR_OP(p) \
     (objR_w >> (BYTE_BIT * (p))) & BYTE_MASK

#else /* !LITTLE_ENDIAN */

#  define objR_OPCODE \
     (objR_w >> (BYTE_BIT * 3)) & BYTE_MASK
#  define objR_OP(p) \
     (objR_w >> (BYTE_BIT * (WORD_BYTE - (p)))) & BYTE_MASK

#endif /* LITTLE_ENDIAN */

#define objR_labelAddr(R, l) \
  l->v

static objR_State *
objR_readerNew(objR_Input *inp)
{
  objR_State *R = new(objR_State);
  R->ptr = R->img = inp->img;
  R->end = inp->img + inp->size;
  return R;
}
]],
  {
    r = OpType{[[#undef r%n
        #define r%n objR_op%n]],
        [[if (r%n == 0) /* r%n can't be > UINT_MAX */
          throwPos(R, ExcBadReg);]]},
    i = OpType{[[#undef i%n_f
        #define i%n_f objR_op%n
        int i%n_sgn, i%n_r;
        Word i%n_v;]],
               function (inst, op)
                 return
        [[if (i%n_f & ~(FLAG_R | FLAG_S | FLAG_W | FLAG_E))
          throwPos(R, ExcBadImmMod);
        i%n_r = (objR_op%n & FLAG_R) ?
          (R->ptr -= 2 - %n, objR_op]] .. tostring(op + 1) ..
          [[) : ((R->ptr -= 3 - %n), 0);
        i%n_v = objR_getNum(R, &i%n_sgn);]]
               end},
    t = OpType{[[#undef t%n
        #define t%n objR_op%n]],
        [[if (objR_op%n == 0 || objR_op%n > LABEL_TYPES)
          throwPos(R, ExcBadLabTy);]]},
    l = OpType{[[int l%n_sgn;
        LabelValue l%n;]],
               function (inst, op)
                 return [[R->ptr -= 4 - %n;
        l%n.n = objR_getNum(R, &l%n_sgn);
        if (l%n_sgn)
          throwPos(R, ExcBadLab);]]
               end},
    n = OpType{"LabelValue l%n;",
               function (inst, op)
                 return "l%n.n = ++T->labels[t" .. tostring(op - 1) ..
                   "];"
               end},
  },
  Translator{
    [[InstWord objR_w;
  Byte objR_op1, objR_op2, objR_op3;]],       -- decls
    "",                                       -- init
    [[objR_w = *(InstWord *)R->ptr;
    objR_op1 = objR_OP(1);
    objR_op2 = objR_OP(2);
    objR_op3 = objR_OP(3);
    o = objR_OPCODE;
    R->ptr = (Byte *)(R->ptr) + WORD_BYTE;]], -- update
    "",                                       -- finish
  }
}
