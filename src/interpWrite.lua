-- Mite interpretive code writer
-- (c) Reuben Thomas 2000

return Writer(
  "Mite interpretive code",
-- Format of interpretive code: same as object code, but with data written out
--   To speed up interpretation, could have top-bit-set instruction variants
--   which take a simple number in the rest of the word; non-top-bit set
--   indicates that flags or multiple words are used; could also write out
--   modified code which expands constants and addresses inline
  [[
#include <stdint.h>

#include "translate.h"

static Word
evalImm(Byte f, int sgn, Word v, SWord r)
{
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
  return v;
}

#define writeUInt(p, n) \
  { \
    Word **uip = (Word **)(p); \
    *(*uip)++ = (n); \
    extras = PTR_BYTE; \
  }

#define DANGLE_MAXLEN PTR_BYTE
#define RESOLVE_IMG NULL
#define RESOLVE_PTR NULL
]],
  {
    Inst("lab",    "bufExt(t->labAddr[t1], t->labSize[t1], " .. 
                   "t->labels[t1] * PTR_BYTE); " ..
                   "t->labAddr[t1][t->labels[t1]] = t1 == LABEL_D " ..
                   "? t->wPtr - t->wImg : t->rPtr - t->rImg;"),
    Inst("mov",   ""), Inst("movi",  ""), Inst("ldl",   ""),
    Inst("ld",    ""), Inst("st",    ""), Inst("gets",  ""),
    Inst("sets",  ""), Inst("pop",   ""), Inst("push",  ""),
    Inst("add",   ""), Inst("sub",   ""), Inst("mul",   ""),
    Inst("div",   ""), Inst("rem",   ""), Inst("and",   ""),
    Inst("or",    ""), Inst("xor",   ""), Inst("sl",    ""),
    Inst("srl",   ""), Inst("sra",   ""), Inst("teq",   ""),
    Inst("tlt",   ""), Inst("tltu",  ""), Inst("b",     ""),
    Inst("br",    ""), Inst("bf",    ""), Inst("bt",    ""),
    Inst("call",  ""), Inst("callr", ""), Inst("ret",   ""),
    Inst("calln", ""),
    Inst("lit",    "*(Word *)t->wPtr = evalImm(i1_f, i1_sgn, " ..
                   "i1_v, i1_r); t->wPtr += PTR_BYTE"),
    Inst("litl",   "addDangle(t, t1, l2); t->wPtr += PTR_BYTE"),
    Inst("space",  "sp = evalImm(i1_f, i1_sgn, i1_v, i1_r) * " ..
                   "PTR_BYTE;ensure(sp); memset(t->wPtr, 0, sp); " ..
                   "t->wPtr += sp"),
  },
  Translator("Word sp;",                       -- decls
             [[for (ty = 0; ty < LABEL_TYPES; ty++)
    t->labAddr[ty] = bufNew(t->labSize[ty], INIT_LABS * PTR_BYTE);]],
                                                    -- init
             "ensure(PTR_BYTE);",                   -- update
             [[for (ty = 0; ty < LABEL_TYPES; ty++)
                 bufShrink(t->labAddr[ty], t->labSize[ty]);]]
                                                    -- finish
  )
)
