/* Mite translator types and functions
   (c) Reuben Thomas 2000
*/


#ifndef MITE_TRANSLATE
#define MITE_TRANSLATE


#include <stddef.h>
#include <stdint.h>
#include <limits.h>

#include "util.h"


typedef int Bool;
typedef uint8_t Byte;
typedef int8_t SByte;
typedef uint32_t Word;
typedef int32_t SWord;

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

#define INST_MAXLEN 4096 /* Maximum amount of code generated for an
                            instruction */

#define ensure(n) \
  bufExt(t->wImg, t->wSize, (uintptr_t)(t->wPtr - t->wImg + (n)))

#include "instEnum.h"
struct Inst { const char *name; Opcode opcode; };
#include "insts.h"

typedef unsigned int Register;

/* Mapping from instruction to operand types */
typedef unsigned int OpList;
extern OpList opType[];

/* Label types */
typedef enum {
  LABEL_B = 1, LABEL_S, LABEL_D
} LabelType;
#define LABEL_TYPES LABEL_D

/* Label value */
typedef union {
  uintptr_t n;
  Byte *p;
} LabelValue;

/* Label */
typedef struct {
  LabelType ty;
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

/* Translator state */
typedef struct {
  Byte *rImg, *rEnd, *rPtr;
  Byte *wImg, *wPtr;
  uintptr_t wSize, labels[LABEL_TYPES], labSize[LABEL_TYPES];
  Dangle *dangles, *dangleEnd;
  Byte *labAddr[LABEL_TYPES]; /* Code writer label address arrays */
  HashTable *labHash; /* Assembly reader table of label names */
  Bool eol; /* Assembly reader EOL state */
} TState;

typedef TState *Translator(Byte *rImg, Byte *rEnd);

#define INIT_IMAGE_SIZE 16384
#define INIT_LABS 256

void
addDangle(TState *t, LabelType ty, LabelValue n);

void
align(TState *t);

TState *
translatorNew(Byte *img, Byte *end);

#endif
