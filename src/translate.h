/* Mite translator types and functions
   (c) Reuben Thomas 2000
*/


#ifndef MITE_TRANSLATE
#define MITE_TRANSLATE


#include <stddef.h>
#include <stdint.h>
#include <limits.h>

#include "endian.h"
#include "util.h"
#include "types.h"
#include "const.h"
#include "except.h"
#include "buffer.h"
#include "list.h"
#include "hash.h"
#include "file.h"


/* Instruction set */
#include "instEnum.h"
struct Inst {
  const char *name;
  Opcode opcode;
};
#include "insts.h"

/* Register type */
typedef unsigned int Register;

/* Label types */
typedef enum {
  LABEL_B = 1, LABEL_S, LABEL_D
} LabelType;
#define LABEL_TYPES LABEL_D

/* Label value */
typedef union {
  Word n;
  void *p;
} LabelValue;

/* Label */
typedef struct {
  LabelType ty;
  LabelValue v; /* (assigned by reader) */
} Label;

/* Dangling label list node */
typedef struct _Dangle {
  Label *l;
  ptrdiff_t off; /* offset into image */
  struct _Dangle *next;
} Dangle;

/* Immediate number flag bits */
#define FLAG_E 8
#define FLAG_S 4
#define FLAG_W 2
#define FLAG_R 1

/* Translator state */
typedef struct {
  void *img;
  Word size;
  Word labels[LABEL_TYPES];
  Dangle *dangles
  Dangle *dangleEnd;
} TState;

/* Extend a write buffer */
#define ensure(n) \
  bufExt (W->img, W->size, (uintptr_t)(W->ptr - W->img + (n)))

#endif
