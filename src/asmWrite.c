/* Mite assembly writer
   (c) Reuben Thomas 2000
*/


#include <stdint.h>
#include <string.h>
#include <ctype.h>
#include <math.h>
#include <limits.h>

#include "except.h"
#include "buffer.h"
#include "translate.h"


/* maximum number of octal digits in a Word
   (upper bound on max. no. of decimal digits) */
#define WORD_MAXLEN (sizeof(Word) * CHAR_BIT / 3)

static void
putChar(TState *t, char c)
{
  bufExt(t->wImg, t->wSize, t->wPtr - t->wImg + 1U);
  *t->wPtr++ = c;
}

static void
putStr(TState *t, const char *s, uintptr_t len)
{
  bufExt(t->wImg, t->wSize, t->wPtr - t->wImg + len);
  memcpy(t->wPtr, s, len);
  t->wPtr += len;
}

static uintptr_t
writeNum(Byte *s, uintptr_t n)
{
  uintptr_t last = n ? log10(n) : 0;
  s += last;
  do {
    *s-- = '0' + n % 10;
    n /= 10;
  } while (n);
  return last + 1;
}

static void
putNum(TState *t, uintptr_t n)
{
  t->wPtr += writeNum(t->wPtr, n);
}

static void
putLabTy(TState *t, unsigned int ty)
{
  switch (ty) {
  case LABEL_B:
    putChar(t, 'b');
    return;
  case LABEL_S:
    putChar(t, 's');
    return;
  case LABEL_D:
    putChar(t, 'd');
    return;
  }
}

#define S(s) putStr(t, s, sizeof(s) / sizeof(char) - 1)

static void
putImm(TState *t, int f, int n, uintptr_t v, uintptr_t r)
{
  if (f & FLAG_E)
    putChar(t, 'e');
  if (f & FLAG_S)
    putChar(t, 's');
  if (f & FLAG_W)
    putChar(t, 'w');
  if (n)
    putChar(t, '-');
  putNum(t, v);
  if (r) {
    S(">>");
    putNum(t, r);
  }
}

#define NL \
  *(t->wPtr)++ = '\n'

#define SP \
  *(t->wPtr)++ = ' '

#define R(r) \
  SP;
  putNum(t, r)

#define LabTy(L) \
  SP;
  putLabTy(t, L)

#define Lab(ty, l) \
  SP;
  putLabTy(t, ty);
  addDangle(t, ty, l)

#define Imm(f, n, v, r) \
  SP;
  putImm(t, f, n, v, r)


#define putInt(t, sgn, n) \
  t->wPtr += writeInt(t->wPtr, sgn, n)
#define putUInt(t, n) \
  putInt(t, 0, n)


#define wrLab(L1, l2)          S("lab"); LabTy(L1); Lab(L1, l2); NL
#define wrMov(r1, r2)          S("mov"); R(r1); R(r2); NL
#define wrMovi(r1, f, n, v, r) S("movi"); R(r1); Imm(f, n, v, r); NL
#define wrLdl(r1, l2)          S("ldl"); R(r1); Lab(LABEL_D, l2); NL
#define wrLd(r1, r2)           S("ld"); R(r1); R(r2); NL
#define wrSt(r1, r2)           S("st"); R(r1); R(r2); NL
#define wrGets(r1)             S("gets"); R(r1); NL
#define wrSets(r1)             S("sets"); R(r1); NL
#define wrPop(r1)              S("pop"); R(r1); NL
#define wrPush(r1)             S("push"); R(r1); NL
#define wrAdd(r1, r2, r3)      S("add"); R(r1); R(r2); R(r3); NL
#define wrSub(r1, r2, r3)      S("sub"); R(r1); R(r2); R(r3); NL
#define wrMul(r1, r2, r3)      S("mul"); R(r1); R(r2); R(r3); NL
#define wrDiv(r1, r2, r3)      S("div"); R(r1); R(r2); R(r3); NL
#define wrRem(r1, r2, r3)      S("rem"); R(r1); R(r2); R(r3); NL
#define wrAnd(r1, r2, r3)      S("and"); R(r1); R(r2); R(r3); NL
#define wrOr(r1, r2, r3)       S("or"); R(r1); R(r2); R(r3); NL
#define wrXor(r1, r2, r3)      S("xor"); R(r1); R(r2); R(r3); NL
#define wrSl(r1, r2, r3)       S("sl"); R(r1); R(r2); R(r3); NL
#define wrSrl(r1, r2, r3)      S("srl"); R(r1); R(r2); R(r3); NL
#define wrSra(r1, r2, r3)      S("sra"); R(r1); R(r2); R(r3); NL
#define wrTeq(r1, r2, r3)      S("teq"); R(r1); R(r2); R(r3); NL
#define wrTlt(r1, r2, r3)      S("tlt"); R(r1); R(r2); R(r3); NL
#define wrTltu(r1, r2, r3)     S("tltu"); R(r1); R(r2); R(r3); NL
#define wrB(l1)                S("b"); Lab(LABEL_B, l1); NL
#define wrBr(r1)               S("br"); R(r1); NL
#define wrBf(r1, l2)           S("bf"); R(r1); Lab(LABEL_B, l2); NL
#define wrBt(r1, l2)           S("bt"); R(r1); Lab(LABEL_B, l2); NL
#define wrCall(l1)             S("call"); Lab(LABEL_S, l1); NL
#define wrCallr(r1)            S("callr"); R(r1); NL
#define wrRet()                S("ret"); NL
#define wrCalln(r1)            S("calln"); R(r1); NL
#define wrLit(f, n, v, r)      S("lit"); Imm(f, n, v, r); NL
#define wrLitl(L1, l2)         S("litl"); Lab(L1, l2); NL
#define wrSpace(f, n, v, r)    S("space"); Imm(f, n, v, r); NL

static uintptr_t
writeUInt(Byte **s, uintptr_t n)
{
  *s += writeNum(*s, n);
  return 0;
}

#define DANGLE_MAXLEN WORD_MAXLEN
#define RESOLVE_IMG NULL
#define RESOLVE_PTR NULL
