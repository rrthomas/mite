-- Mite interpretive code writer
-- (c) Reuben Thomas 2000

return Writer{
  "Mite interpretive code",
-- The interpretive code writer merely works out the label addresses.
-- The original object code is actually interpreted.
  [[/* Interpreter writer output */
/* Interpreter state should contain:

   Registers (R array, S, P)
   Code image (two pointers)
   Label arrays
   Data image (purely to be able to free it)
   Stack (two pointers for now, eventually a linked list)
*/
typedef struct {
  Byte *img;
  uintptr_t size, labels[LABEL_TYPES];
  Byte *labAddr[LABEL_TYPES]; /* label address arrays */
} interpW_Output;
]],
  [[
#include <stdint.h>


/* Interpreter writer state */
typedef struct {
  Byte *img, *ptr;
  uintptr_t size, labSize[LABEL_TYPES];
  Byte *labAddr[LABEL_TYPES]; /* label address arrays */
} interpW_State;

static Word
evalImm(Byte f, int sgn, int r, Word v)
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

#define interpW_UInt(p, n) \
  { \
    Word **uip = (Word **)(p); \
    *(*uip)++ = (n); \
    extras = PTR_BYTE; \
  }

#define DANGLE_MAXLEN PTR_BYTE
#define RESOLVE_IMG NULL
#define RESOLVE_PTR NULL

static interpW_State *
interpW_writerNew(void)
{
  interpW_State *W = new(interpW_State);
  W->img = bufNew(W->size, INIT_IMAGE_SIZE);
  W->ptr = W->img;
  return W;
}

#define A(i) \
  *W->ptr = &i ## Action(state); \
  W->ptr += PTR_BYTE;
]],
"",
  {
    Inst{"lab",   "bufExt(W->labAddr[t1], W->labSize[t1], " .. 
                  "T->labels[t1] * PTR_BYTE); " ..
                  "W->labAddr[t1][T->labels[t1]] = t1 == LABEL_D " ..
                  "? W->ptr - W->img : R->ptr - R->img"},
    Inst{"mov",   ""},    Inst{"movi",  ""},    Inst{"ldl",   ""},
    Inst{"ld",    ""},    Inst{"st",    ""},    Inst{"gets",  ""},
    Inst{"sets",  ""},    Inst{"pop",   ""},    Inst{"push",  ""},
    Inst{"add",   ""},    Inst{"sub",   ""},    Inst{"mul",   ""},
    Inst{"div",   ""},    Inst{"rem",   ""},    Inst{"and",   ""},
    Inst{"or",    ""},    Inst{"xor",   ""},    Inst{"sl",    ""},
    Inst{"srl",   ""},    Inst{"sra",   ""},    Inst{"teq",   ""},
    Inst{"tlt",   ""},    Inst{"tltu",  ""},    Inst{"b",     ""},
    Inst{"br",    ""},    Inst{"bf",    ""},    Inst{"bt",    ""},
    Inst{"call",  ""},    Inst{"callr", ""},    Inst{"ret",   ""},
    Inst{"calln", ""},
    Inst{"lit",   "*(Word *)W->ptr = evalImm(i1_f, i1_sgn, " ..
                  "i1_r, i1_v); W->ptr += PTR_BYTE"},
    Inst{"litl",  "addDangle(T, t1, l2, W->ptr - W->img); " ..
                  "W->ptr += PTR_BYTE"},
    Inst{"space", "sp = evalImm(i1_f, i1_sgn, i1_r, i1_v) * " ..
                  "PTR_BYTE; ensure(sp); memset(W->ptr, 0, sp); " ..
                  "W->ptr += sp"},
  },
  Translator{"Word sp;",                            -- decls
             [[for (ty = 0; ty < LABEL_TYPES; ty++)
    W->labAddr[ty] = bufNew(W->labSize[ty], INIT_LABS * PTR_BYTE);]],
                                                    -- init
             "ensure(PTR_BYTE);",                   -- update
             [[for (ty = 0; ty < LABEL_TYPES; ty++) {
    bufShrink(W->labAddr[ty], T->labels[t1] * PTR_BYTE);
    out->labels[ty] = T->labels[ty];
    out->labAddr[ty] = W->labAddr[ty];
  }
  out->img = W->img;
  out->size = W->ptr - W->img;]]          -- finish
  },
  1
}
