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
}
]],
  resolve =
[[#define objW_UInt (p, n) \
  { \
    Word len = writeInt (*(p), 0, (n)); \
    *(p) += len; \
    extras = len & INST_ALIGN; \
  }

#define objW_DANGLE_MAXLEN (INST_BYTE * 2)
#define objW_RESOLVE_IMG NULL
#define objW_RESOLVE_PTR NULL
]],
  macros =
[[#undef B
#undef W
#undef Lab
#undef Imm

#define B(b) \
  *W->ptr++ = (Byte)b

#ifdef LITTLE_ENDIAN
#  define W(a, b, c, d) \
     *(InstWord *)W->ptr = a | (b << BYTE_BIT) | \
       (c << (BYTE_BIT * 2)) | (d << (BYTE_BIT * 3)); \
     W->ptr += INST_BYTE
#else /* !LITTLE_ENDIAN */
#  define W(a, b, c, d) \
     *(InstWord *)W->ptr = (a << (BYTE_BIT * 3)) | \
       (b << (BYTE_BIT * 2)) | (c << BYTE_BIT) | d; \
     W->ptr += INST_BYTE
#endif /* LITTLE_ENDIAN */

#define Lab(off, ty, l) \
  addDangle (T, ty, l, W->ptr - W->img + off)

#define Imm(f, sgn, v, r) \
  *W->ptr++ = (Byte)(f); \
  if (r) \
    *W->ptr++ = (Byte)r; \
  W->ptr += writeInt (W->ptr, sgn, v)
]],
  inst = {
    Inst{"lab",    "W (OP_LAB, t1, 0, 0)"},
    Inst{"mov",    "W (OP_MOV, r1, r2, 0)"},
    Inst{"movi",   "B (OP_MOVI); B (r1); Imm (i2_f, i2_sgn, i2_v, i2_r)"},
    Inst{"ldl",    "W (OP_LDL, r1, 0, 0); Lab (-2, LABEL_D, l2)"},
    Inst{"ld",     "W (OP_LD, r1, r2, 0)"},
    Inst{"st",     "W (OP_ST, r1, r2, 0)"},
    Inst{"gets",   "W (OP_GETS, r1, 0, 0)"},
    Inst{"sets",   "W (OP_SETS, r1, 0, 0)"},
    Inst{"pop",    "W (OP_POP, r1, 0, 0)"},
    Inst{"push",   "W (OP_PUSH, r1, 0, 0)"},
    Inst{"add",    "W (OP_ADD, r1, r2, r3)"},
    Inst{"sub",    "W (OP_SUB, r1, r2, r3)"},
    Inst{"mul",    "W (OP_MUL, r1, r2, r3)"},
    Inst{"div",    "W (OP_DIV, r1, r2, r3)"},
    Inst{"rem",    "W (OP_REM, r1, r2, r3)"},
    Inst{"and",    "W (OP_AND, r1, r2, r3)"},
    Inst{"or",     "W (OP_OR, r1, r2, r3)"},
    Inst{"xor",    "W (OP_XOR, r1, r2, r3)"},
    Inst{"sl",     "W (OP_SL, r1, r2, r3)"},
    Inst{"srl",    "W (OP_SRL, r1, r2, r3)"},
    Inst{"sra",    "W (OP_SRA, r1, r2, r3)"},
    Inst{"teq",    "W (OP_TEQ, r1, r2, r3)"},
    Inst{"tlt",    "W (OP_TLT, r1, r2, r3)"},
    Inst{"tltu",   "W (OP_TLTU, r1, r2, r3)"},
    Inst{"b",      "W (OP_B, 0, 0, 0); Lab (-3, LABEL_B, l1)"},
    Inst{"br",     "W (OP_BR, r1, 0, 0)"},
    Inst{"bf",     "W (OP_BF, r1, 0, 0); Lab (-2, LABEL_B, l2)"},
    Inst{"bt",     "W (OP_BT, r1, 0, 0); Lab (-2, LABEL_B, l2)"},
    Inst{"call",   "W (OP_CALL, 0, 0, 0); Lab (-3, LABEL_S, l1)"},
    Inst{"callr",  "W (OP_CALLR, r1, 0, 0)"},
    Inst{"ret",    "W (OP_RET, 0, 0, 0)"},
    Inst{"calln",  "W (OP_CALLN, r1, 0, 0)"},
    Inst{"lit",    "B (OP_LIT); Imm (i1_f, i1_sgn, i1_v, i1_r)"},
    Inst{"litl",   "W (OP_LITL, t1, 0, 0); Lab (-2, t1, l2)"},
    Inst{"space",  "B (OP_SPACE); Imm (i1_f, i1_sgn, i1_v, i1_r)"},
  },
  trans = Translator{"",              -- decls
             "",                      -- init
             "ensure (INST_MAXLEN);", -- update
             [[out->img = W->img;
  out->size = W->ptr - W->img;]],     -- finish
  },
}
