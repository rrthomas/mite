/* The interpreter should really use a non-verifying version of the
   object code reader

   Add readObjFast.lua that simply adds #define NO_CHECK to the front
   of readObj's C code.

   Parametrise mkTrans.lua further so that the control loop can be
   abstracted (and indeed the function signature). Thus allow an
   interpreter state instead of a translator state to be passed in.

   i.e. load a reader, a writer and a controller. Have a controller
   for translation and one for interpretation.

   Interpreter state should contain:

   Registers (R array, S, P)
   Code image (two pointers)
   Data image (two pointers)
   Stack (two pointers for now, eventually a linked list)
   */

#include "translate.h"


static SWord
intg(InstWord *p)
{
  SWord n = ((*p & 0x40000000) ? -1 : 0);
  do n = (n << 31) | (*p++ & 0x7fffffff);
  while ((p[-1] & 0x80000000) == 0);
  /* check p does not exceed imgEnd */
  return n;
}

/* Should have verifying and unverifying versions of these routines in translate.c */

static Word
getBits(InstWord *p, Word n)
{
  int i, endBit, bits;
  Word w;
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
  } while (endBit == 0);
  n -= 1 << bits;
  return n;
}

/* Can this mutated evalImm be re-commoned up? */
static Word
num(InstWord *p, Byte f)
{
  Word h = *p & (BYTE_SIGN_BIT - 1);
  Word v;
  int sgn = -(h >> (BYTE_BIT - 2));
  v = getBits(p, (Word)sgn);
  if (sgn)
    v = (Word)(-(SWord)v);
#ifndef LITTLE_ENDIAN
  if (f & FLAG_E)
    v = PTR_BYTE - v;
#endif
  /* s is 1 for the interpreter */
  if (f & FLAG_W)
    v *= PTR_BYTE;
  if (r > 0) {
    if (r > (SWord)PTR_BIT)
      r = PTR_BIT;
    v = (v >> r) | (v << (PTR_BIT - r));
  } else {
    if (r < 0) {
      if (r < -(SWord)PTR_BIT)
        r = -PTR_BIT;
      v = (v >> -r) | (v << (PTR_BIT - -r));
    }
  }
  return sgn ? (Word)(-(SWord)n) : n;
}

#define checkDiv(d)    if (d == 0) return ExcDivByZero;
#define checkShift(s)  if (s > PTR_BIT) return ExcBadShift;

#define setP(x) P = (x); checkP
#define checkP \
  if (P > (Word *)imgEnd || P < (Word *)img) \
    return ExcBadP;

#define setS(x) S = (x); checkS
#define checkS \
  if (S > stkEnd || P < stk) \
    return ExcBadS;

/* Need a linked list of stack frames */
#define stackExtend(s) return ExcBadS
#define extendS if (S == stk) stackExtend

#define op__(_)
#define op_r(r) \
  r = I & 0xff; \
  I >>= CHAR_BIT
#define op_i(i) \
  i = num(P, I & 0xff); \
  I >>= CHAR_BIT;
#define op_t(r) \
  r = I & 0xff; \
  I >>= CHAR_BIT
#define op_l(l) \
  l = (SWord)intg(P); \
  I >>= CHAR_BIT;

#define OP(op, t1, t2, t3)  \
  break; case op: op_ ## t1 (o1); op_ ## t2 (o2); op_ ## t3 (o3)

#define REGS 8

Word
miteRun(Byte *img, Word imgSize, Byte *labAddr[LABEL_TYPES])
{
  Byte op, *imgEnd = img + imgSize;
  InstWord I, *P, *S;
  SWord R[REGS], o1, o2, o3;
  Word *stk, stkSize = 1024;
  P = (Word *)img;
  stk = new(stkSize * PTR_BYTE);
  S = stk + stkSize;
  for (;;) {
    I = *P;
    setP(P + 1);
    op = I & 0xff;
    I >>= CHAR_BIT;
    switch (op) {
    default: return ExcBadInst;
    OP(OP_MOV,   r, r, _); R[o1] = R[o2];
    OP(OP_MOVI,  r, i, _); R[o1] = num(P, o2);
    OP(OP_LDL,   r, l, _); R[o1] = labAddr[LABEL_D][o2];
    OP(OP_LD,    r, r, _); if (R[o2] & PTR_MASK) return ExcBadAddr;
                           R[o1] = *(SWord *)R[o2];
    OP(OP_ST,    r, r, _); if (R[o2] & PTR_MASK) return ExcBadAddr;
                           *(SWord *)R[o1] = R[o2];
    OP(OP_GETS,  r, _, _); R[o1] = (SWord)S;
    OP(OP_SETS,  r, _, _); setS(R[o1]);
    OP(OP_POP,   r, _, _); R[o1] = *S; setS(S + 1);
    OP(OP_PUSH,  r, _, _); extendS; setS(S - 1); *S = R[o1];
    OP(OP_ADD,   r, r, r); R[o1] = R[o2] + R[o3];
    OP(OP_SUB,   r, r, r); R[o1] = R[o2] - R[o3];
    OP(OP_MUL,   r, r, r); R[o1] = R[o2] * R[o3];
    OP(OP_DIV,   r, r, r); checkDiv((Word)R[o3]);
                           R[o1] = (Word)R[o2] / (Word)R[o3];
    OP(OP_REM,   r, r, r); checkDiv((Word)R[o3]);
                           R[o1] = (Word)R[o2] % (Word)R[o3];
    OP(OP_AND,   r, r, r); R[o1] = R[o2] & R[o3];
    OP(OP_OR,    r, r, r); R[o1] = R[o2] | R[o3];
    OP(OP_XOR,   r, r, r); R[o1] = R[o2] ^ R[o3];
    OP(OP_SL,    r, r, r); checkShift((Word)R[o3]);
                           R[o1] = R[o2] << R[o3];
    OP(OP_SRL,   r, r, r); checkShift((Word)R[o3]);
                           R[o1] = (Word)R[o2] >> R[o3];
    OP(OP_SRA,   r, r, r); checkShift((Word)R[o3]);
                           R[o1] = R[o2] >> R[o3];
    OP(OP_TEQ,   r, r, r); R[o1] = R[o2] == R[o3];
    OP(OP_TLT,   r, r, r); R[o1] = R[o2] < R[o3];
    OP(OP_TLTU,  r, r, r); R[o1] = (Word)R[o2] < (Word)R[o3];
    OP(OP_B,     l, _, _); setP(o1);
    OP(OP_BR,    r, _, _); setP(R[o1]);
    OP(OP_BF,    r, l, _); if (!R[o1]) setP(o2);
    OP(OP_BT,    r, l, _); if (R[o1]) setP(o2);
    OP(OP_CALL,  l, _, _); extendS; setS(S - 1); *S = (SWord)P; setP(o1 + 1);
    OP(OP_CALLR, r, _, _); extendS; setS(S - 1); *S = (SWord)P; setP(o1 + 1);
    OP(OP_RET,   _, _, _); if (S == stkEnd) return ExcRet;
                           setP(*S); setS(S + 1);
    OP(OP_CALLN, r, _, _); (*(void (*)(void))(*(SWord *)R[o1]))();
    }
  }
}
