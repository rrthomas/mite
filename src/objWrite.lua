-- Mite object writer
-- (c) Reuben Thomas 2000

return {
  writes = "Mite object",
  output =
[[/* Object writer output */
typedef struct {
  Byte *img;
  Word size;
} objW_Output;
]],
  prelude =
[[#include <stdint.h>
#include <limits.h>


/* Object writer state */
typedef struct {
  Byte *img, *ptr;
  Word size;
} objW_State;

/* Store w in the rest of the current instruction word in big-endian
   order; the data given in w must fit in p mod INST_BYTE bytes */
static void
writeBytes (Byte *p, Word w)
{
  int i = INST_BYTES_LEFT (p) - 1;
  do {
    p[i--] = (Byte)w; /* TODO: Check this cast works as expected */
    w >>= BYTE_BIT;
  } while (i >= 0);
}

/* Write an integer: sgn is 0 for +ve, 1 for -ve; n is the value */
static Word
writeInt (Byte *p, int sgn, Word n)
{
  int len = 1;
  int cur = (INST_BYTES_LEFT (p) << BYTE_SHIFT) - 1;
  Word bytes = 0;
  while (n >> len && len < (int)INST_BIT)
    len++;
  if (sgn)
    n = (Word)(-(SWord)n);
  while ((bytes += (cur + 1) >> BYTE_SHIFT), len > cur) {
    len -= cur; /* Number of bits left */
    writeBytes (p, (Word)(n >> len));
    cur = INST_BIT - 1;
  }
  writeBytes (p, (Word)(n & ((1 << cur) - 1)) /* Mask cur bits */
	     | (1 << cur)); /* Add 1 bit to last word */
  return bytes;
}

static objW_State *
objW_writerNew (void)
{
  objW_State *W = new (objW_State);
  W->img = bufNew (W->size, INIT_IMAGE_SIZE);
  W->ptr = W->img;
  return W;
}]],
  resolve =
[[#define objW_UInt(p, n) \
  { \
    Word len = writeInt (*(p), 0, (n)); \
    *(p) += len; \
    extras = len & INST_ALIGN; \
  }

#define objW_DANGLE_MAXLEN (INST_BYTE * 2)
#define objW_RESOLVE_IMG NULL
#define objW_RESOLVE_PTR NULL]],
  macros =
[[#undef B
#undef W
#undef Lab
#undef Imm

#define B(b) \
  *W->ptr++ = (Byte)b

#ifdef LITTLE_ENDIAN_MITE
#  define W(a, b, c, d) \
     *(InstWord *)W->ptr = a | (b << BYTE_BIT) | \
       (c << (BYTE_BIT * 2)) | (d << (BYTE_BIT * 3)); \
     W->ptr += INST_BYTE
#else /* !LITTLE_ENDIAN_MITE */
#  define W(a, b, c, d) \
     *(InstWord *)W->ptr = (a << (BYTE_BIT * 3)) | \
       (b << (BYTE_BIT * 2)) | (c << BYTE_BIT) | d; \
     W->ptr += INST_BYTE
#endif /* LITTLE_ENDIAN_MITE */

#define Lab(off, ty, l) \
  addDangle (T, ty, l, W->ptr - W->img + off)

#define Num(n) \
  *W->ptr++ = writeInt (W->ptr, 0, n)
  
#define Imm(f, sgn, v, r) \
  *W->ptr++ = (Byte)(f); \
  if (r) \
    *W->ptr++ = (Byte)r; \
  W->ptr += writeInt (W->ptr, sgn, v)

#define Arg(ty, size) \
  *W->ptr++ = (Byte)(size); \
  if (ty == ARG_TYPE_B) \
    W->ptr += writeInt (W->ptr, 0, size)]],

  inst = {
    Inst {"lab",     "W (OP_LAB, t1, 0, 0)"},
    Inst {"mov",     "W (OP_MOV, r1, r2, 0)"},
    Inst {"movi",    "B (OP_MOVI); B (r1); " ..
                     "Imm (i2_f, i2_sgn, i2_v, i2_r)"},
    Inst {"ldl",     "W (OP_LDL, r1, 0, 0); Lab (-2, LABEL_D, l2)"},
    Inst {"ld",      "W (OP_LD, s1, r2, r3)"},
    Inst {"st",      "W (OP_ST, s1, r2, r3)"},
    Inst {"ldo",     "W (OP_LDO, s1, r2, r3); W (r4, 0, 0, 0)"},
    Inst {"sto",     "W (OP_STO, s1, r2, r3); W (r4, 0, 0, 0)"},
    Inst {"add",     "W (OP_ADD, r1, r2, r3)"},
    Inst {"sub",     "W (OP_SUB, r1, r2, r3)"},
    Inst {"mul",     "W (OP_MUL, r1, r2, r3)"},
    Inst {"div",     "W (OP_DIV, r1, r2, r3)"},
    Inst {"rem",     "W (OP_REM, r1, r2, r3)"},
    Inst {"and",     "W (OP_AND, r1, r2, r3)"},
    Inst {"or",      "W (OP_OR, r1, r2, r3)"},
    Inst {"xor",     "W (OP_XOR, r1, r2, r3)"},
    Inst {"sl",      "W (OP_SL, r1, r2, r3)"},
    Inst {"srl",     "W (OP_SRL, r1, r2, r3)"},
    Inst {"sra",     "W (OP_SRA, r1, r2, r3)"},
    Inst {"teq",     "W (OP_TEQ, r1, r2, r3)"},
    Inst {"tlt",     "W (OP_TLT, r1, r2, r3)"},
    Inst {"tltu",    "W (OP_TLTU, r1, r2, r3)"},
    Inst {"b",       "W (OP_B, 0, 0, 0); Lab (-3, LABEL_B, l1)"},
    Inst {"br",      "W (OP_BR, r1, 0, 0)"},
    Inst {"bf",      "W (OP_BF, r1, 0, 0); Lab (-2, LABEL_B, l2)"},
    Inst {"bt",      "W (OP_BT, r1, 0, 0); Lab (-2, LABEL_B, l2)"},
    Inst {"call",    "W (OP_CALL, 0, 0, 0); Lab (-3, LABEL_S, l1)"},
    Inst {"callr",   "W (OP_CALLR, r1, 0, 0)"},
    Inst {"ret",     "W (OP_RET, 0, 0, 0)"},
    Inst {"salloc",  "W (OP_SALLOC, r1, 0, 0)"},
    Inst {"lit",     "B (OP_LIT); B (s1); Num (n2); Imm (i3_f, i3_sgn, i3_v, i3_r)"},
    Inst {"litl",    "W (OP_LITL, t1, 0, 0); Lab (-2, t1, l2)"},
    Inst {"space",   "B (OP_SPACE); Imm (i1_f, i1_sgn, i1_v, i1_r)"},
    Inst {"func",    "B (OP_FUNC); Imm (i1_f, i1_sgn, i1_v, i1_r)"},
    Inst {"funcv",   "B (OP_FUNCV); Imm (i1_f, i1_sgn, i1_v, i1_r)"},
    Inst {"arg",     "B (OP_ARG); B (r1); Arg (a2_ty, a2_size)"},
    Inst {"callf",   "W (OP_CALLF, 0, 0, 0); Lab (-3, LABEL_F, l1)"},
    Inst {"callfr",  "W (OP_CALLFR, r1, 0, 0)"},
    Inst {"callfn",  "W (OP_CALLFN, r1, 0, 0)"},
    Inst {"getret",  "B (OP_GETRET); B (r1); Arg (a2_ty, a2_size)"},
    Inst {"retf",    "B (OP_RETF); B (r1); Arg (a2_ty, a2_size)"},
    Inst {"retf0",   "W (OP_RETF0, 0, 0, 0)"},
  },

  trans = Translator {
             "",                      -- decls
             "",                      -- init
             "ensure (INST_MAXLEN);", -- update
             [[out->img = W->img;
  out->size = W->ptr - W->img;]],     -- finish
  },
}
