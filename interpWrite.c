/* Mite interpretive code writer
   (c) Reuben Thomas 2001
*/

/* Format of interpretive code: same as object code, but with data written out
     To speed up interpretation, could have top-bit-set instruction variants
     which take a simple number in the rest of the word; non-top-bit set
     indicates that flags or multiple words are used; could also write out
     modified code which expands constants and addresses */


#include <stdint.h>
#include <limits.h>
#include <string.h>

#include "except.h"
#include "Translate.h"
#include "InterpWrite.h"


static uintptr_t
eval(Byte f, int n, uintptr_t v, uintptr_t r)
{
  if (n) v = (uintptr_t)(-(intptr_t)n);
#ifndef LITTLE_ENDIAN
  if (f & FLAG_E) n = PTR_BYTE - n;
#endif
  /* s is 1 for the interpreter */
  if (f & FLAG_W) n *= PTR_BYTE;
  if (r > 0) {
    if (r > PTR_BIT) r = PTR_BIT;
    n = (n >> r) | (n << (PTR_BIT - r));
  }
  if (r < 0) {
    if (r < -PTR_BIT) r = -PTR_BIT;
    n = (n >> -r) | (n << (PTR_BIT - -r));
  }
}

#define Lab(ty, l) addDangle(t, ty, l); ensure(PTR_BYTE); t->wPtr += PTR_BYTE
#define Imm(n) ensure(PTR_BYTE); *(uintptr_t *)t->wPtr = n; t->wPtr += PTR_BYTE
#define Zero(n) l = n * PTR_BYTE; ensure(l); memset(t->wPtr, 0, l); \
  t->wPtr += l

#define wrLab(L1, l2)          newLab(L1, l2)
#define wrMov(r1, r2)
#define wrMovi(r1, f, n, v, r)
#define wrLdl(r1, l2)
#define wrLd(r1, r2)
#define wrSt(r1, r2)
#define wrGets(r1)
#define wrSets(r1)
#define wrPop(r1)
#define wrPush(r1)
#define wrAdd(r1, r2, r3)
#define wrSub(r1, r2, r3)
#define wrMul(r1, r2, r3)
#define wrDiv(r1, r2, r3)
#define wrRem(r1, r2, r3)
#define wrAnd(r1, r2, r3)
#define wrOr(r1, r2, r3)
#define wrXor(r1, r2, r3)
#define wrSl(r1, r2, r3)
#define wrSrl(r1, r2, r3)
#define wrSra(r1, r2, r3)
#define wrTeq(r1, r2, r3)
#define wrTlt(r1, r2, r3)
#define wrTltu(r1, r2, r3)
#define wrB(l1)
#define wrBr(r1)
#define wrBf(r1, l2)
#define wrBt(r1, l2)
#define wrCall(l1)
#define wrCallr(r1)
#define wrRet()
#define wrCalln(r1)
#define wrLit(f, n, v, r)      Imm(eval(f, n, v, r))
#define wrLitl(L1, l2)         Lab(L1, l2)
#define wrSpace(f, n, v, r)    Zero(eval(f, n, v, r))

void
resolve(Translator *t)
{
  Dangle *d;
  for (d = t->dangles->next; d; d = d->next)
    (uintptr_t)d->ins = labelMap(t, d->l).n;
}
