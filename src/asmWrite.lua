-- Mite assembly writer
-- (c) Reuben Thomas 2000

return {
  writes = "Mite object",
  output =
[[/* Assembly writer output */
typedef struct {
  char *img;
  size_t size;
} asmW_Output;
]],
  prelude =
[[#include <stdint.h>
#include <string.h>
#include <ctype.h>
#include <limits.h>


/* Assembly writer state */
typedef struct {
  char *img;
  char *ptr;
  size_t size;
} asmW_State;

#define asmW_char(W, c) \
  *W->ptr++ = c

static void
asmW_str (asmW_State *W, const char *s, Word len)
{
  ensure (len);
  memcpy (W->ptr, s, len);
  W->ptr += len;
}

static void
asmW_num (asmW_State *W, Word n)
{
  W->ptr += writeNum (W->ptr, n);
}

static asmW_State *
asmW_writerNew (void)
{
  asmW_State *W = new (asmW_State);
  W->img = bufNew (W->size, INIT_IMAGE_SIZE);
  W->ptr = W->img;
  return W;
}]],
  resolve =
[[#define asmW_UInt(s, n) \
  *(s) += writeNum ((char *)*(s), (n)); \
  extras = 0

#define asmW_DANGLE_MAXLEN INST_MAXLEN
#define asmW_RESOLVE_IMG NULL
#define asmW_RESOLVE_PTR NULL]],
  macros =
[[#undef S
#undef NL
#undef SP
#undef R
#undef LabTy
#undef Lab
#undef Imm

#define S(s) \
  asmW_str (W, s, sizeof (s) - 1)

#define NL \
  *(W->ptr)++ = '\n'

#define SP \
  *(W->ptr)++ = ' '

#define R(r) \
  SP; \
  asmW_num (W, r)

#define LabTy(L) \
  SP; \
  asmW_char (W, labTyToChar (L))

#define Lab(ty, l) \
  SP; \
  asmW_char (W, labTyToChar (ty)); \
  addDangle (T, ty, l, W->ptr - W->img)

#define Imm(f, n, v, r) \
  SP; \
  writeImm (W->ptr, f, n, v, r)]],
  inst = {
    Inst {"lab",    "S (\"lab\"); LabTy (t1); Lab (t1, l2); NL;"},
    Inst {"mov",    "S (\"mov\"); R (r1); R (r2); NL;"},
    Inst {"movi",   "S (\"movi\"); R (r1); " ..
                    "Imm (i2_f, i2_sgn, i2_v, i2_r); NL;"},
    Inst {"ldl",    "S (\"ldl\"); R (r1); Lab (LABEL_D, l2); NL;"},
    Inst {"ld",     "S (\"ld\"); R (r1); R (r2); NL;"},
    Inst {"st",     "S (\"st\"); R (r1); R (r2); NL;"},
    Inst {"gets",   "S (\"gets\"); R (r1); NL;"},
    Inst {"sets",   "S (\"sets\"); R (r1); NL;"},
    Inst {"pop",    "S (\"pop\"); R (r1); NL;"},
    Inst {"push",   "S (\"push\"); R (r1); NL;"},
    Inst {"add",    "S (\"add\"); R (r1); R (r2); R (r3); NL;"},
    Inst {"sub",    "S (\"sub\"); R (r1); R (r2); R (r3); NL;"},
    Inst {"mul",    "S (\"mul\"); R (r1); R (r2); R (r3); NL;"},
    Inst {"div",    "S (\"div\"); R (r1); R (r2); R (r3); NL;"},
    Inst {"rem",    "S (\"rem\"); R (r1); R (r2); R (r3); NL;"},
    Inst {"and",    "S (\"and\"); R (r1); R (r2); R (r3); NL;"},
    Inst {"or",     "S (\"or\"); R (r1); R (r2); R (r3); NL;"},
    Inst {"xor",    "S (\"xor\"); R (r1); R (r2); R (r3); NL;"},
    Inst {"sl",     "S (\"sl\"); R (r1); R (r2); R (r3); NL;"},
    Inst {"srl",    "S (\"srl\"); R (r1); R (r2); R (r3); NL;"},
    Inst {"sra",    "S (\"sra\"); R (r1); R (r2); R (r3); NL;"},
    Inst {"teq",    "S (\"teq\"); R (r1); R (r2); R (r3); NL;"},
    Inst {"tlt",    "S (\"tlt\"); R (r1); R (r2); R (r3); NL;"},
    Inst {"tltu",   "S (\"tltu\"); R (r1); R (r2); R (r3); NL;"},
    Inst {"b",      "S (\"b\"); Lab (LABEL_B, l1); NL;"},
    Inst {"br",     "S (\"br\"); R (r1); NL;"},
    Inst {"bf",     "S (\"bf\"); R (r1); Lab (LABEL_B, l2); NL;"},
    Inst {"bt",     "S (\"bt\"); R (r1); Lab (LABEL_B, l2); NL;"},
    Inst {"call",   "S (\"call\"); Lab (LABEL_S, l1); NL;"},
    Inst {"callr",  "S (\"callr\"); R (r1); NL;"},
    Inst {"ret",    "S (\"ret\"); NL;"},
    Inst {"calln",  "S (\"calln\"); R (r1); NL;"},
    Inst {"lit",    "S (\"lit\"); " ..
                    "Imm (i1_f, i1_sgn, i1_v, i1_r); NL;"},
    Inst {"litl",   "S (\"litl\"); Lab (t1, l2); NL;"},
    Inst {"space",  "S (\"space\"); " ..
                    "Imm (i1_f, i1_sgn, i1_v, i1_r); NL;"},
  },
  trans = Translator {
    "",                          -- decls
    "",                          -- init
    "ensure (INST_MAXLEN);",     -- update
    [[out->img = W->img;
  out->size = W->ptr - W->img;]] -- finish
  },
}
