/* Mite object writer
   Reuben Thomas 2001
*/


#include <stdint.h>
#include <limits.h>

#include "endian.h"
#include "except.h"
#include "translate.h"


/* Store w into the rest of the current instruction word in big-endian order
 * The data given in w must fit in p mod WORD_BYTE bytes */
static void
writeBytes(Byte *p, uint32_t w)
{
  int i = WORD_BYTES_LEFT(p) - 1;
  do {
    p[i--] = (Byte)w; /* Check this cast works as expected */
    w >>= BYTE_BIT;
  } while (i >= 0);
}

/* Write an integer; sgn is 0 for +ve, 1 for -ve, and n is the value */
static uintptr_t
writeInt(Byte *p, int sgn, uintptr_t n)
{
  int len = 1, cur = (WORD_BYTES_LEFT(p) << BYTE_SHIFT) - 1;
  uintptr_t bytes = 0;
  while (n >> len && len < (int)WORD_BIT) len++; 
  if (sgn) n = (uintptr_t)(-(intptr_t)n);
  while ((bytes += (cur + 1) >> BYTE_SHIFT), len > cur) {
    len -= cur; /* Number of bits left */
    writeBytes(p, (uint32_t)(n >> len));
    cur = WORD_BIT - 1;
  }
  writeBytes(p, (uint32_t)(n & ((1 << cur) - 1)) /* Mask to length cur */
	     | (1 << cur)); /* Add 1 bit to last word */
  return bytes;
}

#define NUM_MAX_LENGTH PTR_BYTE + WORD_BYTE

#define B(b) *t->wPtr++ = (Byte)b

#ifdef LITTLE_ENDIAN
#  define W(a, b, c, d) *(Word *)t->wPtr = a | (b << BYTE_BIT) | \
     (c << (BYTE_BIT * 2)) | (d << (BYTE_BIT * 3)); t->wPtr += WORD_BYTE
#else /* !LITTLE_ENDIAN */
#  define W(a, b, c, d) *(Word *)t->wPtr = (a << (BYTE_BIT * 3)) | \
     (b << (BYTE_BIT * 2)) | (c << BYTE_BIT) | d; t->wPtr += WORD_BYTE
#endif /* LITTLE_ENDIAN */

#define Lab(ty, l) addDangle(t, ty, l); align(t)
#define Imm(f, n, v, r) \
  *t->wPtr++ = (Byte)(f); if (r) *t->wPtr++ = (Byte)r; putInt(t, n, v)

#define putInt(t, sgn, n) t->wPtr += writeInt(t->wPtr, sgn, n)
#define putUInt(t, n) putInt(t, 0, n)

#define wrLab(L1, l2)          W(OP_LAB, L1, 0, 0)
#define wrMov(r1, r2)          W(OP_MOV, r1, r2, 0)
#define wrMovi(r1, f, n, v, r) B(OP_MOVI); B(r1); Imm(f, n, v, r)
#define wrLdl(r1, l2)          B(OP_LDL); B(r1); Lab(LABEL_D, l2)
#define wrLd(r1, r2)           W(OP_LD, r1, r2, 0)
#define wrSt(r1, r2)           W(OP_ST, r1, r2, 0)
#define wrGets(r1)             W(OP_GETS, r1, 0, 0)
#define wrSets(r1)             W(OP_SETS, r1, 0, 0)
#define wrPop(r1)              W(OP_POP, r1, 0, 0)
#define wrPush(r1)             W(OP_PUSH, r1, 0, 0)
#define wrAdd(r1, r2, r3)      W(OP_ADD, r1, r2, r3)
#define wrSub(r1, r2, r3)      W(OP_SUB, r1, r2, r3)
#define wrMul(r1, r2, r3)      W(OP_MUL, r1, r2, r3)
#define wrDiv(r1, r2, r3)      W(OP_DIV, r1, r2, r3)
#define wrRem(r1, r2, r3)      W(OP_REM, r1, r2, r3)
#define wrAnd(r1, r2, r3)      W(OP_AND, r1, r2, r3)
#define wrOr(r1, r2, r3)       W(OP_OR, r1, r2, r3)
#define wrXor(r1, r2, r3)      W(OP_XOR, r1, r2, r3)
#define wrSl(r1, r2, r3)       W(OP_SL, r1, r2, r3)
#define wrSrl(r1, r2, r3)      W(OP_SRL, r1, r2, r3)
#define wrSra(r1, r2, r3)      W(OP_SRA, r1, r2, r3)
#define wrTeq(r1, r2, r3)      W(OP_TEQ, r1, r2, r3)
#define wrTlt(r1, r2, r3)      W(OP_TLT, r1, r2, r3)
#define wrTltu(r1, r2, r3)     W(OP_TLTU, r1, r2, r3)
#define wrB(l1)                B(OP_B); Lab(LABEL_B, l1)
#define wrBr(r1)               W(OP_BR, r1, 0, 0)
#define wrBf(r1, l2)           B(OP_BF); B(r1); Lab(LABEL_B, l2)
#define wrBt(r1, l2)           B(OP_BT); B(r1); Lab(LABEL_B, l2)
#define wrCall(l1)             B(OP_CALL); Lab(LABEL_S, l1)
#define wrCallr(r1)            W(OP_CALLR, r1, 0, 0)
#define wrRet()                W(OP_RET, 0, 0, 0)
#define wrCalln(r1)            W(OP_CALLN, r1, 0, 0)
#define wrLit(f, n, v, r)      B(OP_LIT); Imm(f, n, v, r)
#define wrLitl(L1, l2)         B(OP_LITL); B(L1); Lab(L1, l2)
#define wrSpace(f, n, v, r)    B(OP_SPACE); Imm(f, n, v, r)

static uintptr_t
writeUInt(Byte **p, uintptr_t n)
{
  uintptr_t len = writeInt(*p, 0, n);
  *p += len;
  return len & WORD_ALIGN;
}

#define DANGLE_MAXLEN (WORD_BYTE * 2)
#define RESOLVE_IMG NULL
#define RESOLVE_PTR NULL
