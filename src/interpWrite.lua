-- Mite interpretive code writer
-- (c) Reuben Thomas 2000

return {
  writes = "Mite interpretive code",
-- The interpretive code writer merely works out the label addresses.
-- The original object code is actually interpreted.
  output =
[[/* Interpreter writer output */
/* Interpreter state should contain:

   Registers (R array, S, P)
   Code image (two pointers)
   Label arrays
   Data image (purely to be able to free it)
   Stack (two pointers for now, eventually a linked list)
*/
typedef struct {
  Byte *cImg;
  Byte *dImg;
  Word cSize;
  Word dSize;
  Word labels[LABEL_TYPES];
  Byte *labAddr[LABEL_TYPES]; /* label address arrays */
} interpW_Output;
]],
  prelude =
[[#include <stdint.h>


/* Interpreter writer state */
typedef struct {
  Byte *img;
  Byte *ptr;
  Word size;
  Word labSize[LABEL_TYPES];
  Byte *labAddr[LABEL_TYPES]; /* label address arrays */
} interpW_State;

static Word
evalImm (Byte f, int sgn, int r, Word v)
{
  if (sgn)
    v = (Word)(-(SWord)v);
#ifdef WORDS_BIGENDIAN
  if (f & FLAG_E)
    v = WORD_BYTE - v;
#endif
  /* s is 1 for the interpreter */
  if (f & FLAG_W)
    v *= WORD_BYTE;
  if (r > 0) {
    if (r > (SWord)WORD_BIT)
      r = WORD_BIT;
    v = (v >> r) | (v << (WORD_BIT - r));
  } else {
    if (r < 0) {
      if (r < -(SWord)WORD_BIT)
        r = -WORD_BIT;
      v = (v >> -r) | (v << (WORD_BIT - -r));
    }
  }
  return v;
}

static interpW_State *
interpW_writerNew (void)
{
  interpW_State *W = new (interpW_State);
  W->img = bufNew (W->size, INIT_IMAGE_SIZE);
  W->ptr = W->img;
  return W;
}]],
  resolve =
[[#define interpW_UInt(p, n) \
  { \
    Word **uip = (Word **)(p); \
    *(*uip)++ = (n); \
    extras = WORD_BYTE; \
  }

#define DANGLE_MAXLEN WORD_BYTE
#define RESOLVE_IMG NULL
#define RESOLVE_PTR NULL]],
  macros =
[[#define A(i) \
  *W->ptr = &i ## Action (state); \
  W->ptr += WORD_BYTE;]],
  inst = {
    Inst {"lab",   "bufExt (W->labAddr[t1], W->labSize[t1], " .. 
                   "T->labels[t1] * WORD_BYTE); " ..
                   "W->labAddr[t1][T->labels[t1]] = t1 == LABEL_D " ..
                   "? W->ptr - W->img : R->ptr - R->img"},
    Inst {"mov",   ""},
    Inst {"movi",  ""},
    Inst {"ldl",   ""},
    Inst {"ld",    ""},
    Inst {"st",    ""},
    Inst {"gets",  ""},
    Inst {"sets",  ""},
    Inst {"pop",   ""},
    Inst {"push",  ""},
    Inst {"add",   ""},
    Inst {"sub",   ""},
    Inst {"mul",   ""},
    Inst {"div",   ""},
    Inst {"rem",   ""},
    Inst {"and",   ""},
    Inst {"or",    ""},
    Inst {"xor",   ""},
    Inst {"sl",    ""},
    Inst {"srl",   ""},
    Inst {"sra",   ""},
    Inst {"teq",   ""},
    Inst {"tlt",   ""},
    Inst {"tltu",  ""},
    Inst {"b",     ""},
    Inst {"br",    ""},
    Inst {"bf",    ""},
    Inst {"bt",    ""},
    Inst {"call",  ""},
    Inst {"callr", ""},
    Inst {"ret",   ""},
    Inst {"calln", ""},
    Inst {"lit",   "*(Word *)W->ptr = evalImm (i1_f, i1_sgn, " ..
                   "i1_r, i1_v); W->ptr += WORD_BYTE"},
    Inst {"litl",  "addDangle (T, t1, l2, W->ptr - W->img); " ..
                  "W->ptr += WORD_BYTE"},
    Inst {"space", "sp = evalImm (i1_f, i1_sgn, i1_r, i1_v) * " ..
                   "WORD_BYTE; ensure (sp); memset (W->ptr, 0, sp); " ..
                   "W->ptr += sp"},
  },
  trans = Translator {
             "Word sp;",                            -- decls
             [[for (ty = 0; ty < LABEL_TYPES; ty++)
    W->labAddr[ty] = bufNew (W->labSize[ty], INIT_LABS * WORD_BYTE);]],
                                                    -- init
             "ensure (WORD_BYTE);",                 -- update
             [[for (ty = 0; ty < LABEL_TYPES; ty++) {
    bufShrink (W->labAddr[ty], T->labels[ty] * WORD_BYTE);
    out->labels[ty] = T->labels[ty];
    out->labAddr[ty] = W->labAddr[ty];
  }
  out->dImg = W->img;
  out->dSize = W->ptr - W->img;]]                   -- finish
  },
}
