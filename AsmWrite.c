/* Mite assembly writer
 * Reuben Thomas    24/11/00-20/4/01 */


#include <stdint.h>
#include <string.h>
#include <ctype.h>
#include <math.h>
#include <limits.h>

#include <rrt/except.h>
#include <rrt/memory.h>

#include "Translate.h"


/* maximum number of octal digits in a uintptr_t */
#define SIZE_T_MAXLEN (sizeof(uintptr_t) * CHAR_BIT / 3)

/* Instructions indexed by opcode */
static const char *inst[] = {
  "", /* opcodes start at 0x01 */
  "lab",   "mov",   "movi",  "ldl",   "ld",    "st",
  "gets",  "sets",  "pop",   "push",  "add",   "sub",
  "mul",   "div",   "rem",   "and",   "or",    "xor",
  "sl",    "srl",   "sra",   "teq",   "tlt",   "tltu",
  "b",     "br",    "bf",    "bt",    "call",  "callr",
  "ret",   "calln", "lit",   "litl",  "space"
};

static void
putChar(Translator *t, char c)
{
  bufExt(t->wImg, t->wSize, t->wPtr - t->wImg + 1U);
  *t->wPtr++ = c;
}

static void
putStr(Translator *t, const char *s, uintptr_t len)
{
  bufExt(t->wImg, t->wSize, t->wPtr - t->wImg + len);
  memcpy(t->wPtr, s, len);
  t->wPtr += len;
}

static uintptr_t
writeNum(char *s, uintptr_t n)
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
putNum(Translator *t, uintptr_t n)
{
  bufExt(t->wImg, t->wSize, t->wPtr - t->wImg + SIZE_T_MAXLEN);
  t->wPtr += writeNum(t->wPtr, n);
}

static void
putLabTy(Translator *t, unsigned int ty)
{
  switch (ty) {
    case LABEL_B: putChar(t, 'b');  return;
    case LABEL_S: putChar(t, 's');  return;
    case LABEL_D: putChar(t, 'd');  return;
  }
}

static void
putLab(Translator *t, Label *l)
{
  putChar(t, ' ');
  putLabTy(t, l->ty);
  putNum(t, t->reader->labelMap(t, l).n);
}

static void
putLabDangle(Translator *t, Label *l)
{
  putLabTy(t, l->ty);
  addDangle(t, l);
}

static void
putImm(Translator *t, Immediate *i)
{
  if (i->e) putChar(t, 'e');
  if (i->s) putChar(t, 's');
  if (i->w) putChar(t, 'w');
  if (i->n) putChar(t, '-');
  putNum(t, i->v);
  if (i->r) {
    putStr(t, ">>", 2);
    putNum(t, i->r);
  }
}

static void
putOp(Translator *t, MiteValue op, unsigned int ty)
{
  switch (ty) {
    case op_r: putNum(t, op.r); break;
    case op_l: putLabTy(t, op.l->ty); putLabDangle(t, op.l); break;
    case op_L: putLabTy(t, op.l->ty); putLab(t, op.l); break;
    case op_b: putLabDangle(t, op.l); break;
    case op_s: putLabDangle(t, op.l); break;
    case op_d: putLabDangle(t, op.l); break;
    case op_i: putImm(t, op.i); break;
  }
}

static void
putInst(Translator *t, unsigned int i, MiteValue op1, MiteValue op2,
	MiteValue op3)
{
  unsigned int ops;
  
  putStr(t, inst[i], strlen(inst[i]));
  putChar(t, ' ');
  ops = opType[i];
  if (OP1(ops))
    putOp(t, op1, OP1(ops));
  if (OP2(ops)) {
    putChar(t, ' ');
    putOp(t, op2, OP2(ops));
  }
  if (OP3(ops)) {
    putChar(t, ' ');
    putOp(t, op3, OP3(ops));
  }
  putChar(t, '\n');
}

static uintptr_t
insertNum(Byte **s, uintptr_t n)
{
  *s += writeNum((char *)*s, n);
  return 0;
}

static void
resolve(Translator *t)
{
  Byte *fImg;
  Dangle *d;
  uintptr_t n;
 
  for (d = t->dangles->next, n = 0; d; d = d->next, n++);
  fImg = excMalloc(t->wPtr - t->wImg + n * SIZE_T_MAXLEN);
  insertDangles(t, fImg, fImg, insertNum);
}
