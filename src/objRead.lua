-- Mite object reader
-- (c) Reuben Thomas 2000


return Reader(
  "Mite object code",
  [[
/* Need a post-pass to verify everything else (what is there?) */

     
#include <stdint.h>
#include <limits.h>

#include "endian.h"
#include "except.h"
#include "translate.h"


/* set excLine to the current offset into the image, then throw an
   exception */ 
static void
throwPos(TState *t, const char *fmt, ...)
{
  va_list ap;
  va_start(ap, fmt);
  excLine = t->rPtr - t->rImg;
  vThrow(fmt, ap);
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

static uintptr_t
getBits(TState *t, uintptr_t n)
{
#define p t->rPtr
  int i, endBit, bits;
  uint32_t w;
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
    throwPos(t, "badly encoded or missing quantity");
  return n;
#undef p
}

static uintptr_t
getNum(TState *t, int *sgnRet)
{
#define p t->rPtr
  Byte *start = p;
  uint32_t h = *p & (BYTE_SIGN_BIT - 1);
  uintptr_t n;
  int sgn;
  unsigned int len;
  sgn = -(h >> (BYTE_BIT - 2));
  n = getBits(t, (uintptr_t)sgn);
  len = (unsigned int)(p - start - 1); /* Don't count first byte,
                                          which is in h */
  if ((BYTE_BIT - 1) * len +
      bits((int)(sgn == 0 ? h : ~h & (BYTE_SIGN_BIT - 1)))
      > WORD_BIT + sgn)
    throwPos(t, "number too large");
      /* (BYTE_BIT - 1) * len is the no. of significant bits in the
         bottom bytes bits(...) is the number in the most significant
         byte if we're reading a negative number, the maximum size is
         one less */
  *sgnRet = sgn;
  return sgn ? (uintptr_t)(-(intptr_t)n) : n;
#undef p
}

static const char *badReg = "bad register",
  *badLab = "negative label",
  *badLabTy = "bad label type",
  *badFlags = "bad immediate flags";

#define CHECK__(op)
#define CHECK_l(op)
#define CHECK_n(op)
#define CHECK_f(op) \
  if (op & ~(FLAG_R | FLAG_S | FLAG_W | FLAG_E)) throwPos(t, badFlags)
#define CHECK_r(op) \
  if (op == 0 || op > UINT_MAX) throwPos(t, badReg)
#define CHECK_t(op) \
  if (op == 0 || op > LABEL_TYPES) throwPos(t, badLabTy)

#define OPS(a, b, c) \
  CHECK_ ## a(op1); \
  CHECK_ ## b(op2); \
  CHECK_ ## c(op3)


#ifdef LITTLE_ENDIAN

#  define OPCODE(w) \
     (w) & BYTE_MASK

#  define OP(p) \
     (w >> (BYTE_BIT * (p))) & BYTE_MASK

#else /* !LITTLE_ENDIAN */

#  define OPCODE(w) \
     (w >> (BYTE_BIT * 3)) & BYTE_MASK

#  define \
     OP(p) (w >> (BYTE_BIT * (WORD_BYTE - (p)))) & BYTE_MASK

#endif /* LITTLE_ENDIAN */


#define GET_LAB(p) \
  t->rPtr -= 4 - (p); \
  l.n = getNum(t, &sgn); \
  if (sgn) \
    throwPos(t, badLab)

    w = *(Word *)t->rPtr;
    case OP_LAB:
      OPS(L,_,_);
      l.n = ++t->labels[op1];
      wrLab(op1, l);
      break;
  ]],
  "rdInst(t)", -- rdInst(t)
  "l->v",      -- labelAddr(t, l)
  {
    r = OpType("Register %o = rdReg(t);", ""),
    i = OpType([[Byte %o_f = ;
        SByte %o_sgn;
        uintptr_t %o_v;
        int %o_r;]],
    function (inst, op)
                 
      
#define GET_IMM1 \
  r = (op1 & FLAG_R) ? (t->rPtr--, op2) : ((t->rPtr -= 2), 0); \
  n = getNum(t, &sgn)

#define GET_IMM2 \
  r = (op2 & FLAG_R) ? op3 : (t->rPtr--, 0); \
  n = getNum(t, &sgn)

OpType([[Byte %o_f;
        SByte %o_sgn;
        uintptr_t %o_v;
        int %o_r;]],
        "rdImm(t, &%o_f, &%o_sgn, &%o_v, &%o_r);"),
    t = OpType("LabelType %o = rdLabTy(t);", ""),
    l = OpType(function (inst, op)
                 local ty = labelType(inst, op)
                 return "HashNode *%o_hn = rdLab(t, " .. ty .. [[);
        LabelValue %o;]]
               end,
        "%o.p = (Byte *)%o_hn->key;"),
    n = OpType(function (inst, op)
                 local ty = labelType(inst, op)
                 return "HashNode *%o_hn = rdLab(t, " .. ty .. ");"
               end,
               function (inst, op)
                 local ty = labelType(inst, op)
                 return [[l = %o_hn->body;
        t->labels[]] .. ty .. [[]++;
        if (l->v.n != 0)
          throw("duplicate definition for `%s'", %o_hn->key);
        l->v.n = t->labels[]] .. ty .. "];"
               end),
  },
  Translator(
    "Word w;",               -- decls
    [[t->labelHash = hashNew(4096);
  t->eol = 0;]],             -- init
    "t->rPtr += WORD_BYTE;", -- update
    "INST_MAXLEN"            -- maxInstLen
  )
)
