/* Mite abstract grammar
 * Reuben Thomas    1/12/00-20/5/01 */


#ifndef MITE_ABSGRAM
#define MITE_ABSGRAM

#include <stddef.h>
#include <stdint.h>
#include <limits.h>

#include <rrt/memory.h>
#include <rrt/hash.h>


/* typedef uint8_t Byte; */
typedef int8_t SByte;
typedef uint32_t Word;

#define BYTE_BIT CHAR_BIT /* Number of bits in a byte */
#define BYTE_SIGN_BIT (1U << (BYTE_BIT - 1)) /* 1 in sign bit of a byte */
#define BYTE_SHIFT 3 /* Shift to turn bytes into bits */
#define BYTE_MASK ((Byte)-1) /* Mask for a byte */

#define WORD_BYTE (sizeof(Word)) /* Number of bytes in Word */
#define WORD_BIT (sizeof(Word) * CHAR_BIT) /* Number of bits in Word */
#define WORD_ALIGN (WORD_BYTE - 1) /* Mask to align a Word address */
#define WORD_SIGN_BIT (1U << (WORD_BIT - 1)) /* 1 in sign bit of a word */
#define WORD_SHIFT 2 /* Shift to turn words into bytes */
#define WORD_BYTES_LEFT(p) (WORD_BYTE - ((uintptr_t)p & WORD_ALIGN))

#define PTR_BYTE (sizeof(uintptr_t)) /* Number of bytes in uintptr_t */
#define PTR_BIT (sizeof(uintptr_t) * CHAR_BIT) /* No. of bits in uintptr_t */
#define PTR_MASK (PTR_BYTE - 1)
  /* Number of bytes left in the Word from p */
#define PTR_BYTES_LEFT(p) (PTR_BYTE - ((uintptr_t)p & PTR_MASK))
  /* Number of bytes left in the Word from p */

#define ensure(n) bufExt(t->wImg, t->wSize, t->wPtr - t->wImg + (n))

/* Instruction opcodes */
enum {
  OP_LAB = 0x01, OP_MOV, OP_MOVI, OP_LDL, OP_LD, OP_ST, OP_GETS, OP_SETS,
  OP_POP, OP_PUSH, OP_ADD, OP_SUB, OP_MUL, OP_DIV, OP_REM, OP_AND, OP_OR,
  OP_XOR, OP_SL, OP_SRL, OP_SRA, OP_TEQ, OP_TLT, OP_TLTU, OP_B, OP_BR, OP_BF,
  OP_BT, OP_CALL, OP_CALLR, OP_RET, OP_CALLN, OP_LIT, OP_LITL, OP_SPACE 
};
#define INSTS OP_SPACE

/* Operand types */
enum {
  op__, op_r, op_l, op_L, op_b, op_s, op_d, op_i 
};

/* Mapping from instruction to operand types */
extern unsigned int opType[];

/* Extract operand types from opType entries
 * (opposite of OPS() macro in Translate.c) */
#define OP1(ty) ((ty) & 0xf)
#define OP2(ty) (((ty) >> 4) & 0xf)
#define OP3(ty) (((ty) >> 8) & 0xf)

/* Label types */
enum {
  LABEL_B = 1, LABEL_S, LABEL_D, LABEL_TYPES = 3
};
extern const char *labelType[]; /* names */

/* Label value */
typedef union {
  uintptr_t n;
  Byte *p;
} LabelValue;

/* Label */
typedef struct {
  unsigned int ty;
  LabelValue v; /* (assigned by reader) */
} Label;

/* Dangling label list node */
typedef struct _Dangle {
  Label *l;
  ptrdiff_t ins; /* insertion point */
  struct _Dangle *next;
} Dangle;

/* Immediate number flag bits */
#define FLAG_E 8
#define FLAG_S 4
#define FLAG_W 2
#define FLAG_R 1

/* Immediate numbers */
typedef struct {
  unsigned long v; /* value */
  int r; /* rotation */
  Byte f; /* flags */
  SByte sgn; /* sign */
} Immediate;

/* Mite values */
typedef union {
  unsigned int r;
  unsigned int ty;
  Label *l;
  Immediate *i;
} MiteValue;

/* Translator state */
typedef struct {
  Byte *rImg, *rEnd, *rPtr;
  Byte *wImg, *wPtr;
  uintptr_t wSize, labels[LABEL_TYPES];
  Dangle *dangles, *dangleEnd;
  HashTable *labelHash; /* Assembly reader hash table for label names */
  int eol; /* Assembly reader EOL state */
} Translator;

typedef Translator *TranslatorFunction(Byte *rImg, Byte *rEnd);

#define MIN_IMAGE_SIZE 16384

void
addDangle(Translator *t, unsigned int ty, uintptr_t n);

void
insertDangles(Translator *t, Byte *fImg, Byte *fPtr,
	      uintptr_t (*write)(Byte **p, uintptr_t n),
	      LabelValue (*labelMap)(Translator *t, Label *l));

void
align(Translator *t);

void
nullLabNew(Translator *t, unsigned int ty, uintptr_t n);

Translator *
translatorNew(Byte *img, Byte *end);

#endif
