
#line 100 "mit.w"
#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <setjmp.h>
#include "mite.h"


#line 135 "mit.w"
#define max(a, b)  ((a) > (b) ? (a) : (b))
#define min(a, b)  ((a) < (b) ? (a) : (b))

#define raise(e)   longjmp(env, (int)(e))

#define seta(a, n, i, e, o) \
    if ((i) >= (n)) raise(mite_badHeader); \
    (a)[(i)++]= (miteWord)(e) + (o)

#define alloc(p, s) \
    p= malloc(s);  if (!p) raise(mite_memoryFull)

#line 179 "mit.w"
static uint32_t endianness = 1;
#define LITTLE_ENDIAN  (*(int8_t *)&endianness)

#line 203 "mit.w"
#define P_REG    0x7f
#define P        ((uint32_t *)(R[P_REG]))
#define Pp       (miteObject *)&R[P_REG]
#define setP(x)  R[P_REG]= (miteWord)(x)

#define S_REG    0x7e
#define S        ((miteWord *)(R[S_REG]))
#define setS(x)  checkS(x); R[S_REG]= (miteWord)x;
#define checkS(x) \
    if (((miteWord *)(x) > s->_i.S_base) || \
        ((miteWord *)(x) < s->_i.S_base - s->_i.S_size)) \
            raise(mite_badS);

#line 227 "mit.w"
#define stack_extend(s) \
    if (!(s ## _i.S_base= realloc(s ## _i.S_base, \
        (s ## _i.S_size *= 2) * sizeof(miteWord)))) \
            raise(mite_memoryFull)
#define extendS  if (S == s->_i.S_base) stack_extend(s->)

#line 351 "mit.w"
#define bad_instruction \
  { *errp= p; raise(mite_badInstruction); }
#define OPC(op, t1, t2, t3)  \
  break; case op: t1 ## _opc (o1); t2 ## _opc (o2); t3 ## _opc (o3)
#define __opc(_) \
  if (I & 0xff) bad_instruction; \
  I >>= CHAR_BIT
#define r_opc(r) \
  r= I & 0xff; \
  if (r > mite_g) bad_instruction;\
  I >>= CHAR_BIT
#define i_opc(i) \
  i= I & 0xff; \
  if (i > 7) bad_instruction; \
  ver_num(&p, i, prog->cend); \
  I >>= CHAR_BIT;
#define L_opc(l) \
  if ((I & 0xff) < l_branch || (I & 0xff) > l_data) bad_instruction;
#define l_opc(l) \
  l= ver_intg(&p, prog->cend); \
  I >>= CHAR_BIT;

#line 454 "mit.w"
#define OPL(op, t, n) \
  break; case op: t ## _opl (o1, n);
#define i_opl(i, n) \
  i= (I >> (CHAR_BIT * n)) & 0xff; \
   num(&p, i);
#define L_opl(l, n) \
  if ((I & 0xff) == 0 || (I & 0xff) > 3) bad_instruction; \
  I >>= CHAR_BIT;
#define b_opl(l, n) \
  l= intg(&p); \
  type= (I >> (CHAR_BIT * n)) & 0xff; \
  if (type != l_branch || l > d) bad_instruction;
#define s_opl(l, n) \
  l= intg(&p); \
  type= (I >> (CHAR_BIT * n)) & 0xff; \
  if (type != l_sub || l > d) bad_instruction;
#define d_opl(l, n) \
  l= intg(&p); \
  type= (I >> (CHAR_BIT * n)) & 0xff; \
  if (type != l_data || l > d) bad_instruction;

#line 556 "mit.w"
#define __op(_)
#define r_op(r) \
  r= I & 0xff; \
  I >>= CHAR_BIT
#define i_op(i) \
  i= num(Pp, I & 0xff); \
  I >>= CHAR_BIT;
#define b_op(l) \
  l= (miteWord)p->bl[intg(Pp)]; \
  I >>= CHAR_BIT;
#define s_op(l) \
  l= (miteWord)p->sl[intg(Pp)]; \
  I >>= CHAR_BIT;
#define d_op(l) \
  l= (miteWord)p->dl[intg(Pp)]; \
  I >>= CHAR_BIT;

#line 583 "mit.w"
#define OP(op, t1, t2, t3)  \
  break; case op: t1 ## _op (o1); t2 ## _op (o2); t3 ## _op (o3)

#line 106 "mit.w"

#define MITE_PREFIX(x) x

#line 248 "mit.w"
static miteWord
MITE_PREFIX(intg)(miteObject *p
#ifdef MITE_VERIFY
                  , miteObject l
#endif
)
{
    miteWord n= (**p & 0x40000000 ? -1 : 0);

    do n= (n << 31) | (**p++ & 0x7fffffff);
    while ((*p[-1] & 0x80000000) == 0
#ifdef MITE_VERIFY
    && *p < l
#endif
    );

    return n;
}

#line 108 "mit.w"

#define MITE_VERIFY
#undef MITE_PREFIX
#define MITE_PREFIX(x) ver_ ## x

#line 248 "mit.w"
static miteWord
MITE_PREFIX(intg)(miteObject *p
#ifdef MITE_VERIFY
                  , miteObject l
#endif
)
{
    miteWord n= (**p & 0x40000000 ? -1 : 0);

    do n= (n << 31) | (**p++ & 0x7fffffff);
    while ((*p[-1] & 0x80000000) == 0
#ifdef MITE_VERIFY
    && *p < l
#endif
    );

    return n;
}

#line 112 "mit.w"


#line 273 "mit.w"
static void
ver_num(miteObject *p, int flags, miteObject l)
{
    ver_intg(p, l);
    if (flags & 1) ver_intg(p, l);
}

static miteWord
num(miteObject *p, int flags)
{
  miteWord n= intg(p), r;

  if (flags & 8 && !LITTLE_ENDIAN) n= mite_w - n;
  if (flags & 4)                   n *= mite_s;
  if (flags & 2)                   n *= mite_w;
  if (flags & 1) {
    if ((r= intg(p) < 0) r= mite_w + r;
    r= max(0, min(mite_w, r));
    n= ((miteUWord)n >> r) | ((miteUWord)n << (mite_w - r));
  }
  return n;
}

#line 113 "mit.w"


#line 340 "mit.w"
miteProgram *
mite_translate(miteObject o, jmp_buf env, uint32_t **errp)
{
  miteProgram *prog;
  miteObject p;
  miteWord I, *dp= NULL, o1, o2, o3;

#line 376 "mit.w"
  {
    miteWord b, s, d;

    for (p= prog->code, b= s= d= 0; p < prog->cend; p++) {
      int flags= (++*p >> CHAR_BIT) & 0xff;

      switch (*p & 0xff) {
        default: bad_instruction;
        OPC(OP_LAB,   L,_,_);  
#line 438 "mit.w"
                               switch (flags) {
                                 case l_branch:  seta(prog->bl, prog->b, b, p, 1);   break;
                                 case l_sub:     seta(prog->sl, prog->s, s, p, 1);   break;
                                 case l_data:    seta(prog->dl, prog->d, d, dp, 0);  break;
                                 default:        bad_instruction;
                               }
                               
#line 384 "mit.w"

        OPC(OP_MOV,   r,r,_);
        OPC(OP_MOVI,  r,i,_);
        OPC(OP_LDL,   r,l,_);
        OPC(OP_LD,    r,r,_);
        OPC(OP_ST,    r,r,_);
        OPC(OP_GETS,  r,_,_);
        OPC(OP_SETS,  r,_,_);
        OPC(OP_POP,   r,_,_);
        OPC(OP_PUSH,  r,_,_);
        OPC(OP_ADD,   r,r,r);
        OPC(OP_SUB,   r,r,r);
        OPC(OP_MUL,   r,r,r);
        OPC(OP_DIV,   r,r,r);
        OPC(OP_REM,   r,r,r);
        OPC(OP_AND,   r,r,r);
        OPC(OP_OR,    r,r,r);
        OPC(OP_XOR,   r,r,r);
        OPC(OP_SL,    r,r,r);
        OPC(OP_SRL,   r,r,r);
        OPC(OP_SRA,   r,r,r);
        OPC(OP_TEQ,   r,r,r);
        OPC(OP_TLT,   r,r,r);
        OPC(OP_TLTU,  r,r,r);
        OPC(OP_B,     l,_,_);
        OPC(OP_BR,    r,_,_);
        OPC(OP_BF,    r,l,_);
        OPC(OP_BT,    r,l,_);
        OPC(OP_CALL,  l,_,_);
        OPC(OP_CALLR, r,_,_);
        OPC(OP_RET,   _,_,_);
        OPC(OP_CALLN, r,_,_);
        OPC(OP_LIT,   _,_,_);
        OPC(OP_LITL,  _,_,_);
        OPC(OP_SPACE, _,_,_);
    }
  }

#line 429 "mit.w"
if (b != prog->b || s != prog->s || d != prog->d) raise(mite_badHeader);

#line 478 "mit.w"
    for (p= prog->code; p < prog->cend; p++) {
      int type;
      miteUWord ops, i;

      switch (*p & 0xff) {
        default: break;
        OPL(OP_MOVI, i, 0);
        OPL(OP_LDL,  d, 1);
        OPL(OP_B,    b, 0);
        OPL(OP_BF,   b, 1);
        OPL(OP_BT,   b, 1);
        OPL(OP_CALL, s, 0);
        case OP_LIT:   
#line 515 "mit.w"
                       ops= num(&p, *p & 0xff);
                       for (i= 0; i < ops; i++) *dp++= num(&p, *p & 0xff);
                       
#line 490 "mit.w"

        case OP_LITL:  
#line 524 "mit.w"
                       ops= intg(&p);
                       for (i= 0; i < ops; i++) {
                         miteUWord l= intg(&p);
                       
                         switch (type) {
                           case 1: *dp++= (miteWord)prog->bl[l];  break;
                           case 2: *dp++= (miteWord)prog->sl[l];  break;
                           case 3: *dp++= (miteWord)prog->dl[l];  break;
                         }
                       }
                       
#line 491 "mit.w"

        case OP_SPACE: 
#line 540 "mit.w"
                       ops= num(&p, *p & 0xff);
                       
                       memset(dp, 0, ops * sizeof(miteWord));
                       dp += ops;
                       
#line 492 "mit.w"

      }
    }

#line 501 "mit.w"
  }

    return prog;
}

#line 114 "mit.w"


#line 596 "mit.w"

#line 633 "mit.w"
#define checkDiv(d)    if (!d) raise(mite_divisionByZero);
#define checkShift(s)  if (s > mite_w) raise(mite_badShift);

#line 596 "mit.w"


miteWord
mite_run(miteProgram *p, mite_State *s, jmp_buf env)
{
  int op;
  uint32_t I;
#define R (*(s->R))
  miteWord o1, o2, o3;

  for (;;) {
    I= *P;  setP(P + 1);
    op= I & 0xff;  I >>= CHAR_BIT;
    switch (op) {
      default:  raise(mite_badInstruction);
      
#line 639 "mit.w"
      OP(OP_MOV,   r, r, _);  R[o1]= R[o2];
      OP(OP_MOVI,  r, i, _);  R[o1]= num(Pp, o2);
      OP(OP_LDL,   r, d, _);  R[o1]= o2;
      OP(OP_LD,    r, r, _);  if (R[o2] & (sizeof(miteWord) - 1))
                                raise(mite_badAddress);
                              R[o1]= *(miteWord *)R[o2];
      OP(OP_ST,    r, r, _);  if (R[o2] & (sizeof(miteWord) - 1))
                                raise(mite_badAddress);
                              *(miteWord *)R[o1]= R[o2];
      OP(OP_GETS,  r, _, _);  R[o1]= (miteWord)S;
      OP(OP_SETS,  r, _, _);  setS(R[o1]);
      OP(OP_POP,   r, _, _);  R[o1]= *S; setS(S + 1);
      OP(OP_PUSH,  r, _, _);  extendS; setS(S - 1); *S= R[o1];
      OP(OP_ADD,   r, r, r);  R[o1]= R[o2] + R[o3];
      OP(OP_SUB,   r, r, r);  R[o1]= R[o2] - R[o3];
      OP(OP_MUL,   r, r, r);  R[o1]= R[o2] * R[o3];
      OP(OP_DIV,   r, r, r);  checkDiv((miteUWord)R[o3]);
                              R[o1]= (miteUWord)R[o2] / (miteUWord)R[o3];
      OP(OP_REM,   r, r, r);  checkDiv((miteUWord)R[o3]);
                              R[o1]= (miteUWord)R[o2] % (miteUWord)R[o3];
      OP(OP_AND,   r, r, r);  R[o1]= R[o2] & R[o3];
      OP(OP_OR,    r, r, r);  R[o1]= R[o2] | R[o3];
      OP(OP_XOR,   r, r, r);  R[o1]= R[o2] ^ R[o3];
      OP(OP_SL,    r, r, r);  checkShift((miteUWord)R[o3]);
                              R[o1]= R[o2] << R[o3];
      OP(OP_SRL,   r, r, r);  checkShift((miteUWord)R[o3]);
                              R[o1]= (miteUWord)R[o2] >> R[o3];
      OP(OP_SRA,   r, r, r);  checkShift((miteUWord)R[o3]);
                              R[o1]= R[o2] >> R[o3];
      OP(OP_TEQ,   r, r, r);  R[o1]= R[o2] == R[o3];
      OP(OP_TLT,   r, r, r);  R[o1]= R[o2] < R[o3];
      OP(OP_TLTU,  r, r, r);  R[o1]= (miteUWord)R[o2] < (miteUWord)R[o3];
      OP(OP_B,     b, _, _);  setP(o1);
      OP(OP_BR,    r, _, _);  setP(R[o1]);
      OP(OP_BF,    r, b, _);  if (!R[o1]) setP(o2);
      OP(OP_BT,    r, b, _);  if (R[o1]) setP(o2);
      OP(OP_CALL,  s, _, _);  extendS; setS(S - 1); *S= (miteWord)P; setP(o1 + 1);
      OP(OP_CALLR, r, _, _);  extendS; setS(S - 1); *S= (miteWord)P; setP(o1 + 1);
      OP(OP_RET,   _, _, _);  setP(*S); setS(S + 1);
      OP(OP_CALLN, r, _, _);  (*(void (*)(void))(*(miteWord *)R[o1]))();
      
#line 611 "mit.w"

    }
  }
#undef R
}

#line 115 "mit.w"

