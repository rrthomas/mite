/* The interpreter should really use a non-verifying version of the
   object code reader: add readObjFast.lua that simply adds #define
   NO_CHECK to the front of readObj's C code.

   Interpreter state should contain:

   Registers (R array, S, P)
   Code image (two pointers)
   Label arrays (data image is implicit in data labels)
   Stack (two pointers for now, eventually a linked list)
   */

#include "translate.h"


/* Should have verifying and unverifying versions of getBits & getNum in translate.c */

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
  i = getNum(P, I & 0xff); \
  I >>= CHAR_BIT;
#define op_t(r) \
  r = I & 0xff; \
  I >>= CHAR_BIT
#define op_l(l) \
  l = (SWord)getBits(P, 0); \
  I >>= CHAR_BIT;

#define OP(op, t1, t2, t3)  \
  break; case op: op_ ## t1 (o1); op_ ## t2 (o2); op_ ## t3 (o3)

#define REGS 8

Word
interp(Byte *img, Word imgSize, Byte *labAddr[LABEL_TYPES])
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
    }
  }
}

    OP(OP_MOV,   r, r, _); R[o1] = R[o2];
    OP(OP_MOVI,  r, i, _); R[o1] = getNum(P, o2);
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
    OP(OP_CALL,  l, _, _); extendS; setS(S - 1); *S = (SWord)P;
                           setP(o1 + 1);
    OP(OP_CALLR, r, _, _); extendS; setS(S - 1); *S = (SWord)P;
                           setP(o1 + 1);
    OP(OP_RET,   _, _, _); if (S == stkEnd) return ExcRet;
                           setP(*S); setS(S + 1);
    OP(OP_CALLN, r, _, _); (*(void (*)(void))(*(SWord *)R[o1]))();
