-- Mite assembly writer
-- (c) Reuben Thomas 2000

return Writer(
  "Mite object",
  [[
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
  *t->wPtr++ = c;
}

static void
putStr(TState *t, const char *s, uintptr_t len)
{
  ensure(len);
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
putLabTy(TState *t, LabelType ty)
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
  SP; \
  putNum(t, r)

#define LabTy(L) \
  SP; \
  putLabTy(t, L)

#define Lab(ty, l) \
  SP; \
  putLabTy(t, ty); \
  addDangle(t, ty, l)

#define Imm(f, n, v, r) \
  SP; \
  putImm(t, f, n, v, r)


#define putInt(t, sgn, n) \
  t->wPtr += writeInt(t->wPtr, sgn, n)
#define putUInt(t, n) \
  putInt(t, 0, n)

static uintptr_t
writeUInt(Byte **s, uintptr_t n)
{
  *s += writeNum(*s, n);
  return 0;
}

#define DANGLE_MAXLEN WORD_MAXLEN
#define RESOLVE_IMG NULL
#define RESOLVE_PTR NULL
  ]],
  {
    Inst("lab",    "S(\"lab\"); LabTy(t1); Lab(t1, l2); NL;"),
    Inst("mov",    "S(\"mov\"); R(r1); R(r2); NL;"),
    Inst("movi",   "S(\"movi\"); R(r1); " ..
                   "Imm(i2_f, i2_sgn, i2_v, i2_r); NL;"),
    Inst("ldl",    "S(\"ldl\"); R(r1); Lab(LABEL_D, l2); NL;"),
    Inst("ld",     "S(\"ld\"); R(r1); R(r2); NL;"),
    Inst("st",     "S(\"st\"); R(r1); R(r2); NL;"),
    Inst("gets",   "S(\"gets\"); R(r1); NL;"),
    Inst("sets",   "S(\"sets\"); R(r1); NL;"),
    Inst("pop",    "S(\"pop\"); R(r1); NL;"),
    Inst("push",   "S(\"push\"); R(r1); NL;"),
    Inst("add",    "S(\"add\"); R(r1); R(r2); R(r3); NL;"),
    Inst("sub",    "S(\"sub\"); R(r1); R(r2); R(r3); NL;"),
    Inst("mul",    "S(\"mul\"); R(r1); R(r2); R(r3); NL;"),
    Inst("div",    "S(\"div\"); R(r1); R(r2); R(r3); NL;"),
    Inst("rem",    "S(\"rem\"); R(r1); R(r2); R(r3); NL;"),
    Inst("and",    "S(\"and\"); R(r1); R(r2); R(r3); NL;"),
    Inst("or",     "S(\"or\"); R(r1); R(r2); R(r3); NL;"),
    Inst("xor",    "S(\"xor\"); R(r1); R(r2); R(r3); NL;"),
    Inst("sl",     "S(\"sl\"); R(r1); R(r2); R(r3); NL;"),
    Inst("srl",    "S(\"srl\"); R(r1); R(r2); R(r3); NL;"),
    Inst("sra",    "S(\"sra\"); R(r1); R(r2); R(r3); NL;"),
    Inst("teq",    "S(\"teq\"); R(r1); R(r2); R(r3); NL;"),
    Inst("tlt",    "S(\"tlt\"); R(r1); R(r2); R(r3); NL;"),
    Inst("tltu",   "S(\"tltu\"); R(r1); R(r2); R(r3); NL;"),
    Inst("b",      "S(\"b\"); Lab(LABEL_B, l1); NL;"),
    Inst("br",     "S(\"br\"); R(r1); NL;"),
    Inst("bf",     "S(\"bf\"); R(r1); Lab(LABEL_B, l2); NL;"),
    Inst("bt",     "S(\"bt\"); R(r1); Lab(LABEL_B, l2); NL;"),
    Inst("call",   "S(\"call\"); Lab(LABEL_S, l1); NL;"),
    Inst("callr",  "S(\"callr\"); R(r1); NL;"),
    Inst("ret",    "S(\"ret\"); NL;"),
    Inst("calln",  "S(\"calln\"); R(r1); NL;"),
    Inst("lit",    "S(\"lit\"); " ..
                   "Imm(i1_f, i1_sgn, i1_v, i1_r); NL;"),
    Inst("litl",   "S(\"litl\"); Lab(t1, l2); NL;"),
    Inst("space",  "S(\"space\"); " ..
                   "Imm(i1_f, i1_sgn, i1_v, i1_r); NL;"), 
  }
)
