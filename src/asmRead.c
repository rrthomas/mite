/* Mite assembly reader
   (c) Reuben Thomas 2000
*/


#include <stdint.h>
#include <limits.h>
#include <ctype.h>
#include <errno.h>
#include <string.h>

#include "except.h"
#include "hash.h"
#include "string.h"
#include "translate.h"


static int
issym(int c)
{
  return isalnum(c) || (c == '_');
}

static int
isimm(int c)
{
  return isxdigit(c) || strchr(">-_swx", c);
}

/* Get next token consisting of characters for which f() returns true into
 * *tok, advancing t->rPtr past it, and discarding leading non-f() characters
 * and comments */
static uintptr_t
getTok(TState *t, char **tok, int (*f)(int))
{ 
#define p t->rPtr
  if (t->eol) {
    excLine++;
    t->eol = 0;
  }
  while (*p && (isspace((char)*p) || (char)*p == '#')) {
    if ((char)*p == '#')
      do {
        p++;
      } while (*p && (char)*p != '\n');
    if ((char)*p == '\n')
      excLine++;
    p++;
  }
  *tok = (char *)p;
  while (f((char)*p)) p++;
  if (*tok == (char *)p)
    throw("missing token");
  if (!isspace((char)*p))
    throw("bad character");
  if ((char)*p == '\n')
    t->eol = 1;
  *p = (Byte)'\0';
  return p++ - (Byte *)*tok;
#undef p
}

static unsigned int
getInstNum(TState *t)
{
  char *tok;
  uintptr_t len = getTok(t, &tok, issym);
  struct Inst *i = findInst(tok, len);
  if (i == NULL)
    throw("bad instruction");
  return (unsigned int)i->opcode;
}

/* Use the function (whose existence ISO C guarantees), not the macro */
#undef isdigit
static MiteValue
getReg(TState *t)
{
  char *tok, *nend;
  unsigned long n;
  MiteValue ret;
  uintptr_t len = getTok(t, &tok, isdigit);
  n = strtoul(tok, &nend, 10);
  if (n > UINT_MAX || (uintptr_t)(nend - tok) != len)
    throw("bad register");
  ret.r = n;
  return ret;
}

static MiteValue
getLabTy(TState *t)
{
  char *tok;
  MiteValue ret;
  uintptr_t len = getTok(t, &tok, isalpha);
  if (len == 1)
    switch (*tok) {
      case 'b':
        ret.ty = LABEL_B;
        return ret;
      case 's':
        ret.ty = LABEL_S;
        return ret;
      case 'd':
        ret.ty = LABEL_D;
        return ret;
    }
  throw("bad label type");
}

static MiteValue
getLab(TState *t, unsigned int ty)
{
  MiteValue ret;
  ret.l = new(Label);
  ret.l->ty = ty;
  getTok(t, (char **)&ret.l->v.p, issym);
  return ret;
}

static MiteValue
getImm(TState *t)
{
  Immediate *i = new(Immediate);
  int rsgn;
  long rl;
  char *tok, *nend;
  MiteValue ret;
  getTok(t, &tok, isimm);
  i->f = 0;
  if (*tok == 'e') {
    tok++;
    i->f |= FLAG_E;
  }
  if (*tok == 's') {
    tok++;
    i->f |= FLAG_S;
  }
  if (*tok == 'w') {
    tok++;
    i->f |= FLAG_W;
  }
  if (*tok == '-') {
    tok++;
    i->sgn = 1;
  } else
    i->sgn = 0;
  errno = 0;
  i->v = strtoul(tok, &nend, 0);
  if (errno == ERANGE || (i->sgn && i->v > (unsigned long)(LONG_MAX) + 1))
    /* rather than -LONG_MIN; we're assuming two's complement anyway, and
     * negating LONG_MIN overflows long before the cast to unsigned long */
    throw("immediate value out of range");
  tok = nend;
  rsgn = 0;
  if (*tok == '>' && tok[1] == '>') {
    tok += 2;
    i->f |= FLAG_R;
    errno = 0;
    if (*tok == '-') {
	tok++;
	rsgn = -1;
    }
    rl = strtoul(tok, &nend, 0);
    if (rl + rsgn > 127 || errno == ERANGE)
      throw("immediate rotation out of range");
    tok = nend;
    i->r = rsgn ? -(int)rl : (int)rl;
  } else
    i->r = 0;
  if (*tok)
    throw("bad immediate");
  ret.i = i;
  return ret;
}

static MiteValue
getOp(TState *t, unsigned int ty)
{
  switch (ty) {
    case op_r:
      return getReg(t);
    case op_l: case op_L:
      return getLab(t, getLabTy(t).ty);
    case op_b:
      return getLab(t, LABEL_B);
    case op_s:
      return getLab(t, LABEL_S);
    case op_d:
      return getLab(t, LABEL_D);
    case op_i:
      return getImm(t);
    default:
      throw("bad operand type");
  }
}

static void
getInst(TState *t, unsigned int *i,
	MiteValue *op1, MiteValue *op2, MiteValue *op3)
{
  unsigned int ops;
  *i = getInstNum(t);
  ops = opType[*i];
  if (OP1(ops))
    *op1 = getOp(t, OP1(ops));
  if (OP2(ops))
    *op2 = getOp(t, OP2(ops));
  if (OP3(ops))
    *op3 = getOp(t, OP3(ops));
}

static LabelValue
labelMap(TState *t, Label *l)
{
  LabelValue ret;
  ret.p = hashFind(t->labelHash, l->v.p);
  return ret;
}

TState *
TRANSLATOR(Byte *rImg, Byte *rEnd)
{
  TState *t = translatorNew(rImg, rEnd);
  unsigned int i;
  MiteValue op1, op2, op3;
  Label *old;
  for (i = 0; i < LABEL_TYPES; i++)
    t->labels[i] = 0;
  t->labelHash = hashNew(4096, hashStrHash, hashStrcmp);
  t->eol = 0;
  while (t->rPtr < t->rEnd) {
    getInst(t, &i, &op1, &op2, &op3);
    excLine += 1;
    bufEnsure(INST_MAXLEN);
    switch (i) {
    case OP_LAB:
      t->labels[op1.l->ty]++;
      if ((old = hashFind(t->labelHash, op1.l->v.p))) {
        if (old->ty != op1.l->ty)
          throw("inconsistent label");
      } else
        hashInsert(t->labelHash, op1.l->v.p, (void *)(t->labels[op1.l->ty]));
      wrLab(op1.l->ty, op1.l->v);
      break;
    case OP_MOV:
      wrMov(op1.r, op2.r);
      break;
    case OP_MOVI:
      wrMovi(op1.r, op2.i->f, op2.i->sgn, op2.i->v, op2.i->r);
      break;
    case OP_LDL:
      wrLdl(op1.r, op1.l->v);
      break;
    case OP_LD:
      wrLd(op1.r, op2.r);
      break;
    case OP_ST:
      wrSt(op1.r, op2.r);
      break;
    case OP_GETS:
      wrGets(op1.r);
      break;
    case OP_SETS:
      wrSets(op1.r);
      break;
    case OP_POP:
      wrPop(op1.r);
      break;
    case OP_PUSH:
      wrPush(op1.r);
      break;
    case OP_ADD:
      wrAdd(op1.r, op2.r, op3.r);
      break;
    case OP_SUB:
      wrSub(op1.r, op2.r, op3.r);
      break;
    case OP_MUL:
      wrMul(op1.r, op2.r, op3.r);
      break;
    case OP_DIV:
      wrDiv(op1.r, op2.r, op3.r);
      break;
    case OP_REM:
      wrRem(op1.r, op2.r, op3.r);
      break;
    case OP_AND:
      wrAnd(op1.r, op2.r, op3.r);
      break;
    case OP_OR:
      wrOr(op1.r, op2.r, op3.r);
      break;
    case OP_XOR:
      wrXor(op1.r, op2.r, op3.r);
      break;
    case OP_SL:
      wrSl(op1.r, op2.r, op3.r);
      break;
    case OP_SRL:
      wrSrl(op1.r, op2.r, op3.r);
      break;
    case OP_SRA:
      wrSra(op1.r, op2.r, op3.r);
      break;
    case OP_TEQ:
      wrTeq(op1.r, op2.r, op3.r);
      break;
    case OP_TLT:
      wrTlt(op1.r, op2.r, op3.r);
      break;
    case OP_TLTU:
      wrTltu(op1.r, op2.r, op3.r);
      break;
    case OP_B:
      wrB(op1.l->v);
      break;
    case OP_BR:
      wrBr(op1.r);
      break;
    case OP_BF:
      wrBf(op1.r, op1.l->v);
      break;
    case OP_BT:
      wrBt(op1.r, op1.l->v);
      break;
    case OP_CALL:
      wrCall(op1.l->v);
      break;
    case OP_CALLR:
      wrCallr(op1.r);
      break;
    case OP_RET:
      wrRet();
      break;
    case OP_CALLN:
      wrCalln(op1.r);
      break;
    case OP_LIT:
      wrLit(op1.i->f, op1.i->sgn, op1.i->v, op1.i->r);
      break;
    case OP_LITL:
      wrLitl(op1.l->ty, op1.l->v);
      break;
    case OP_SPACE:
      wrSpace(op1.i->f, op1.i->sgn, op1.i->v, op1.i->r);
      break;
    default:
      throw("bad instruction");
    }
  }
  excLine = 0;
  resolve(t);
  return t;
}
