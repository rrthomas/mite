#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <setjmp.h>

#include "translate.h"


#define raise(e) longjmp(env, (int)(e))

#define alloc(p, s) \
  p = malloc(s); if (!p) raise(mite_memoryFull)

static uint32_t endianness = 1;
#define LITTLE_ENDIAN  (*(int8_t *)&endianness)

#define P_REG   0x7f
#define P       ((uint32_t *)(R[P_REG]))
#define Pp      (miteObject *)&R[P_REG]
#define setP(x) R[P_REG] = (SWord)(x)

#define S_REG   0x7e
#define S       ((SWord *)(R[S_REG]))
#define setS(x) checkS(x); R[S_REG] = (SWord)x;
#define checkS(x) \
  if (((SWord *)(x) > s->_i.S_base) || \
    ((SWord *)(x) < s->_i.S_base - s->_i.S_size)) \
      raise(mite_badS);

#define stackExtend(s) \
  if (!(s ## _i.S_base = realloc(s ## _i.S_base, \
    (s ## _i.S_size *= 2) * sizeof(SWord)))) \
      raise(mite_memoryFull)
#define extendS if (S == s->_i.S_base) stackExtend(s->)

#define bad_instruction \
  { *errp = p; raise(mite_badInstruction); }

#define __op(_)
#define r_op(r) \
  r = I & 0xff; \
  I >>= CHAR_BIT
#define i_op(i) \
  i = num(Pp, I & 0xff); \
  I >>= CHAR_BIT;
#define b_op(l) \
  l = (SWord)p->bl[intg(Pp)]; \
  I >>= CHAR_BIT;
#define s_op(l) \
  l = (SWord)p->sl[intg(Pp)]; \
  I >>= CHAR_BIT;
#define d_op(l) \
  l = (SWord)p->dl[intg(Pp)]; \
  I >>= CHAR_BIT;

#define OP(op, t1, t2, t3)  \
  break; case op: t1 ## _op (o1); t2 ## _op (o2); t3 ## _op (o3)

static SWord
ver_intg(miteObject *p, miteObject l)
{
  SWord n = (**p & 0x40000000 ? -1 : 0);
  do n = (n << 31) | (**p++ & 0x7fffffff);
  while ((*p[-1] & 0x80000000) == 0 && *p < l);
  return n;
}

static void
ver_num(miteObject *p, int flags, miteObject l)
{
  ver_intg(p, l);
  if (flags & 1) ver_intg(p, l);
}

static SWord
num(miteObject *p, int flags)
{
  SWord n = intg(p), r;
  if (flags & 8 && !LITTLE_ENDIAN)
    n = mite_w - n;
  if (flags & 4)
    n *= mite_s;
  if (flags & 2)
    n *= mite_w;
  if (flags & 1) {
    if ((r = intg(p) < 0)
      r = mite_w + r;
    r = max(0, min(mite_w, r));
    n = ((Word)n >> r) | ((Word)n << (mite_w - r));
  }
  return n;
}

#define checkDiv(d)    if (!d) raise(mite_divisionByZero);
#define checkShift(s)  if (s > mite_w) raise(mite_badShift);

SWord
miteRun(miteProgram *p, mite_State *s, jmp_buf env)
{
  int op;
  uint32_t I;
#define R (*(s->R))
  SWord o1, o2, o3;
  for (;;) {
    I = *P;  setP(P + 1);
    op = I & 0xff;  I >>= CHAR_BIT;
    switch (op) {
    default: raise(mite_badInstruction);
    OP(OP_MOV,   r, r, _);  R[o1] = R[o2];
    OP(OP_MOVI,  r, i, _);  R[o1] = num(Pp, o2);
    OP(OP_LDL,   r, l, _);  R[o1] = o2;
    OP(OP_LD,    r, r, _);  if (R[o2] & (sizeof(SWord) - 1))
                              raise(mite_badAddress);
    R[o1] = *(SWord *)R[o2];
    OP(OP_ST,    r, r, _);  if (R[o2] & (sizeof(SWord) - 1))
                              raise(mite_badAddress);
    *(SWord *)R[o1] = R[o2];
    OP(OP_GETS,  r, _, _);  R[o1] = (SWord)S;
    OP(OP_SETS,  r, _, _);  setS(R[o1]);
    OP(OP_POP,   r, _, _);  R[o1] = *S; setS(S + 1);
    OP(OP_PUSH,  r, _, _);  extendS; setS(S - 1); *S = R[o1];
    OP(OP_ADD,   r, r, r);  R[o1] = R[o2] + R[o3];
    OP(OP_SUB,   r, r, r);  R[o1] = R[o2] - R[o3];
    OP(OP_MUL,   r, r, r);  R[o1] = R[o2] * R[o3];
    OP(OP_DIV,   r, r, r);  checkDiv((Word)R[o3]);
                            R[o1] = (Word)R[o2] / (Word)R[o3];
    OP(OP_REM,   r, r, r);  checkDiv((Word)R[o3]);
                            R[o1] = (Word)R[o2] % (Word)R[o3];
    OP(OP_AND,   r, r, r);  R[o1] = R[o2] & R[o3];
    OP(OP_OR,    r, r, r);  R[o1] = R[o2] | R[o3];
    OP(OP_XOR,   r, r, r);  R[o1] = R[o2] ^ R[o3];
    OP(OP_SL,    r, r, r);  checkShift((Word)R[o3]);
                            R[o1] = R[o2] << R[o3];
    OP(OP_SRL,   r, r, r);  checkShift((Word)R[o3]);
    R[o1] = (Word)R[o2] >> R[o3];
    OP(OP_SRA,   r, r, r);  checkShift((Word)R[o3]);
    R[o1] = R[o2] >> R[o3];
    OP(OP_TEQ,   r, r, r);  R[o1] = R[o2] == R[o3];
    OP(OP_TLT,   r, r, r);  R[o1] = R[o2] < R[o3];
    OP(OP_TLTU,  r, r, r);  R[o1] = (Word)R[o2] < (Word)R[o3];
    OP(OP_B,     l, _, _);  setP(o1);
    OP(OP_BR,    r, _, _);  setP(R[o1]);
    OP(OP_BF,    r, l, _);  if (!R[o1]) setP(o2);
    OP(OP_BT,    r, l, _);  if (R[o1]) setP(o2);
    OP(OP_CALL,  l, _, _);  extendS; setS(S - 1); *S = (SWord)P; setP(o1 + 1);
    OP(OP_CALLR, r, _, _);  extendS; setS(S - 1); *S = (SWord)P; setP(o1 + 1);
    OP(OP_RET,   _, _, _);  setP(*S); setS(S + 1);
    OP(OP_CALLN, r, _, _);  (*(void (*)(void))(*(SWord *)R[o1]))();
    }
  }
#undef R
}
  
int
main(void)
{
  int ret;
  SWord R[256];
  mite_State s;
  jmp_buf env;
  miteProgram *p;
  s.R = &R;
  *s.R[P_REG] = (SWord)(p->code);
  s._i.S_size = 16;
  s._i.S_base = NULL;
  stackExtend(s.);  *s.R[S_REG] = (SWord)(s._i.S_base + s._i.S_size);
  if (!(ret = setjmp(env)))
    mite_run(p, &s, env);
  return ret;
}
