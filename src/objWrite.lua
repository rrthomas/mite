-- Mite object writer
-- (c) Reuben Thomas 2000

return Writer(
  "Mite object",
  [[
#include <stdint.h>
#include <limits.h>

#include "translate.h"


/* Store w in the rest of the current instruction word in big-endian
   order; the data given in w must fit in p mod WORD_BYTE bytes */
static void
writeBytes(Byte *p, Word w)
{
  int i = WORD_BYTES_LEFT(p) - 1;
  do {
    p[i--] = (Byte)w; /* Check this cast works as expected */
    w >>= BYTE_BIT;
  } while (i >= 0);
}

/* Write an integer: sgn is 0 for +ve, 1 for -ve; n is the value */
static Word
writeInt(Byte *p, int sgn, Word n)
{
  int len = 1, cur = (WORD_BYTES_LEFT(p) << BYTE_SHIFT) - 1;
  Word bytes = 0;
  while (n >> len && len < (int)WORD_BIT)
    len++;
  if (sgn)
    n = (Word)(-(SWord)n);
  while ((bytes += (cur + 1) >> BYTE_SHIFT), len > cur) {
    len -= cur; /* Number of bits left */
    writeBytes(p, (Word)(n >> len));
    cur = WORD_BIT - 1;
  }
  writeBytes(p, (Word)(n & ((1 << cur) - 1)) /* Mask cur bits */
	     | (1 << cur)); /* Add 1 bit to last word */
  return bytes;
}

#define NUM_MAX_LENGTH PTR_BYTE + WORD_BYTE

#define B(b) \
  *t->wPtr++ = (Byte)b

#ifdef LITTLE_ENDIAN
#  define W(a, b, c, d) \
     *(InstWord *)t->wPtr = a | (b << BYTE_BIT) | \
       (c << (BYTE_BIT * 2)) | (d << (BYTE_BIT * 3)); \
     t->wPtr += WORD_BYTE
#else /* !LITTLE_ENDIAN */
#  define W(a, b, c, d) \
     *(InstWord *)t->wPtr = (a << (BYTE_BIT * 3)) | \
       (b << (BYTE_BIT * 2)) | (c << BYTE_BIT) | d; \
     t->wPtr += WORD_BYTE
#endif /* LITTLE_ENDIAN */

#define Lab(ty, l) \
  addDangle(t, ty, l); \
  align(t)

#define Imm(f, sgn, v, r) \
  *t->wPtr++ = (Byte)(f); \
  if (r) \
    *t->wPtr++ = (Byte)r; \
  putInt(t, sgn, v)

#define putInt(t, sgn, n) \
  t->wPtr += writeInt(t->wPtr, sgn, n)

#define putUInt(t, n) \
  putInt(t, 0, n)

#define writeUInt(p, n) \
  { \
    Word len = writeInt(*(p), 0, (n)); \
    *(p) += len; \
    extras = len & WORD_ALIGN; \
  }

#define DANGLE_MAXLEN (WORD_BYTE * 2)
#define RESOLVE_IMG NULL
#define RESOLVE_PTR NULL
]],
  {
    Inst("lab",    "W(OP_LAB, t1, 0, 0)"),
    Inst("mov",    "W(OP_MOV, r1, r2, 0)"),
    Inst("movi",   "B(OP_MOVI); B(r1); Imm(i2_f, i2_sgn, i2_v, i2_r)"),
    Inst("ldl",    "B(OP_LDL); B(r1); Lab(LABEL_D, l2)"),
    Inst("ld",     "W(OP_LD, r1, r2, 0)"),
    Inst("st",     "W(OP_ST, r1, r2, 0)"),
    Inst("gets",   "W(OP_GETS, r1, 0, 0)"),
    Inst("sets",   "W(OP_SETS, r1, 0, 0)"),
    Inst("pop",    "W(OP_POP, r1, 0, 0)"),
    Inst("push",   "W(OP_PUSH, r1, 0, 0)"),
    Inst("add",    "W(OP_ADD, r1, r2, r3)"),
    Inst("sub",    "W(OP_SUB, r1, r2, r3)"),
    Inst("mul",    "W(OP_MUL, r1, r2, r3)"),
    Inst("div",    "W(OP_DIV, r1, r2, r3)"),
    Inst("rem",    "W(OP_REM, r1, r2, r3)"),
    Inst("and",    "W(OP_AND, r1, r2, r3)"),
    Inst("or",     "W(OP_OR, r1, r2, r3)"),
    Inst("xor",    "W(OP_XOR, r1, r2, r3)"),
    Inst("sl",     "W(OP_SL, r1, r2, r3)"),
    Inst("srl",    "W(OP_SRL, r1, r2, r3)"),
    Inst("sra",    "W(OP_SRA, r1, r2, r3)"),
    Inst("teq",    "W(OP_TEQ, r1, r2, r3)"),
    Inst("tlt",    "W(OP_TLT, r1, r2, r3)"),
    Inst("tltu",   "W(OP_TLTU, r1, r2, r3)"),
    Inst("b",      "B(OP_B); Lab(LABEL_B, l1)"),
    Inst("br",     "W(OP_BR, r1, 0, 0)"),
    Inst("bf",     "B(OP_BF); B(r1); Lab(LABEL_B, l2)"),
    Inst("bt",     "B(OP_BT); B(r1); Lab(LABEL_B, l2)"),
    Inst("call",   "B(OP_CALL); Lab(LABEL_S, l1)"),
    Inst("callr",  "W(OP_CALLR, r1, 0, 0)"),
    Inst("ret",    "W(OP_RET, 0, 0, 0)"),
    Inst("calln",  "W(OP_CALLN, r1, 0, 0)"),
    Inst("lit",    "B(OP_LIT); Imm(i1_f, i1_sgn, i1_v, i1_r)"),
    Inst("litl",   "B(OP_LITL); B(t1); Lab(t1, l2)"),
    Inst("space",  "B(OP_SPACE); Imm(i1_f, i1_sgn, i1_v, i1_r)"),
  },
  Translator("",                     -- decls
             "",                     -- init
             "ensure(INST_MAXLEN);", -- update
             ""                      -- finish
  )
)
