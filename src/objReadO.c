/* Mite object reader
   (c) Reuben Thomas 2001
*/

/* Need a post-pass to verify everything else (what is there?) */

     
#include <stdint.h>
#include <limits.h>

#include "endian.h"
#include "except.h"
#include "translate.h"


/* set excLine to the current offset into the image, then throw an exception */
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
 * (no. of ones in a 3-bit no. is n - floor(n/2) - floor(n/4)) */
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

#define GET_IMM1 \
  r = (op1 & FLAG_R) ? (t->rPtr--, op2) : ((t->rPtr -= 2), 0); \
  n = getNum(t, &sgn)

#define GET_IMM2 \
  r = (op2 & FLAG_R) ? op3 : (t->rPtr--, 0); \
  n = getNum(t, &sgn)

static LabelValue
labelAddr(TState *t, Label *l)
{
  return l->v;
}

TState *
TRANSLATOR(Byte *rImg, Byte *rEnd)
{
  TState *t = translatorNew(rImg, rEnd);
  Word w;
  Byte op1, op2, op3;
  SByte r;
  intptr_t n;
  LabelValue l;
  int sgn, i;
  for (i = 0; i < LABEL_TYPES; i++)
    t->labels[i] = 0;
  while (t->rPtr < t->rEnd) {
    w = *(Word *)t->rPtr;
    op1 = OP(1);
    op2 = OP(2);
    op3 = OP(3);
    t->rPtr += WORD_BYTE;
    excLine += WORD_BYTE;
    ensure(INST_MAXLEN);
    switch (OPCODE(w)) {
    case OP_LAB:
      OPS(L,_,_);
      l.n = ++t->labels[op1];
      wrLab(op1, l);
      break;
    case OP_MOV:
      OPS(r,r,_);
      wrMov(op1, op2);
      break;
    case OP_MOVI:
      OPS(r,f,_);
      GET_IMM2;
      wrMovi(op1, op2, sgn, n, r);
      break;
    case OP_LDL:
      OPS(r,d,_);
      GET_LAB(2);
      wrLdl(op1, l);
      break;
    case OP_LD:
      OPS(r,r,_);
      wrLd(op1, op2);
      break;
    case OP_ST:
      OPS(r,r,_);
      wrSt(op1, op2);
      break;
    case OP_GETS:
      OPS(r,_,_);
      wrGets(op1);
      break;
    case OP_SETS:
      OPS(r,_,_);
      wrSets(op1);
      break;
    case OP_POP:
      OPS(r,_,_);
      wrPop(op1);
      break;
    case OP_PUSH:
      OPS(r,_,_);
      wrPush(op1);
      break;
    case OP_ADD:
      OPS(r,r,r);
      wrAdd(op1, op2, op3);
      break;
    case OP_SUB:
      OPS(r,r,r);
      wrSub(op1, op2, op3);
      break;
    case OP_MUL:
      OPS(r,r,r);
      wrMul(op1, op2, op3);
      break;
    case OP_DIV:
      OPS(r,r,r);
      wrDiv(op1, op2, op3);
      break;
    case OP_REM:
      OPS(r,r,r);
      wrRem(op1, op2, op3);
      break;
    case OP_AND:
      OPS(r,r,r);
      wrAnd(op1, op2, op3);
      break;
    case OP_OR:
      OPS(r,r,r);
      wrOr(op1, op2, op3);
      break;
    case OP_XOR:
      OPS(r,r,r);
      wrXor(op1, op2, op3);
      break;
    case OP_SL:
      OPS(r,r,r);
      wrSl(op1, op2, op3);
      break;
    case OP_SRL:
      OPS(r,r,r);
      wrSrl(op1, op2, op3);
      break;
    case OP_SRA:
      OPS(r,r,r);
      wrSra(op1, op2, op3);
      break;
    case OP_TEQ:
      OPS(r,r,r);
      wrTeq(op1, op2, op3);
      break;
    case OP_TLT:
      OPS(r,r,r);
      wrTlt(op1, op2, op3);
      break;
    case OP_TLTU:
      OPS(r,r,r);
      wrTltu(op1, op2, op3);
      break;
    case OP_B:
      OPS(b,_,_);
      GET_LAB(1);
      wrB(l);
      break;
    case OP_BR:
      OPS(r,_,_);
      wrBr(op1);
      break;
    case OP_BF:
      OPS(r,b,_);
      GET_LAB(2);
      wrBf(op1, l);
      break;
    case OP_BT:
      OPS(r,b,_);
      GET_LAB(2);
      wrBt(op1, l);
      break;
    case OP_CALL:
      OPS(s,_,_);
      GET_LAB(1);
      wrCall(l);
      break;
    case OP_CALLR:
      OPS(r,_,_);
      wrCallr(op1);
      break;
    case OP_RET:
      OPS(_,_,_);
      wrRet();
      break;
    case OP_CALLN:
      OPS(r,_,_);
      wrCalln(op1);
      break;
    case OP_LIT:
      OPS(f,_,_);
      GET_IMM1;
      wrLit(op1, sgn, n, r);
      break;
    case OP_LITL:
      OPS(l,_,_);
      GET_LAB(2);
      wrLitl(op1, l);
      break;
    case OP_SPACE:
      OPS(f,_,_);
      GET_IMM1;
      wrSpace(op1, sgn, n, r);
      break;
    default:
      throw("bad instruction");
    }
  }
  excLine = 0;
  resolve(t);
  return t;
}
