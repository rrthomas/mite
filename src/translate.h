/* Mite translator types and functions
   (c) Reuben Thomas 2000
*/


#ifndef MITE_TRANSLATE
#define MITE_TRANSLATE

#include "config.h"

#include <stddef.h>
#include <stdint.h>
#include <limits.h>

#include "util.h"
#include "types.h"
#include "const.h"
#include "except.h"
#include "buffer.h"
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

/* Register numbers */
#define REGISTER_MAX 256        /* Biggest register number */
#define REGISTER_S (REGISTER_MAX)
#define REGISTER_F (REGISTER_MAX - 1)

/* Size type */
typedef unsigned int Size;
#define SIZE_A (sizeof (Word))  /* Size of an address */

/* Label types */
typedef enum {
  LABEL_B = 1, LABEL_S, LABEL_D, LABEL_F
} LabelType;
#define LABEL_TYPES LABEL_F

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

/* Function argument type */
typedef enum {
  ARG_TYPE_R = 1, ARG_TYPE_F, ARG_TYPE_B
} ArgType;

/* Translator state */
typedef struct {
  void *img;
  Word size;
  Word labels[LABEL_TYPES];
  Dangle *dangles;
  Dangle *dangleEnd;
} TState;

/* Extend a write buffer */
#define ensure(n) \
  bufExt (W->img, W->size, (uintptr_t)(W->ptr - W->img + (n)))

#endif
