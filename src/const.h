/* Mite translator constants
   (c) Reuben Thomas 2000
*/


#ifndef MITE_CONST
#define MITE_CONST


#include <stdint.h>

#include "types.h"


#define BYTE_BIT CHAR_BIT /* Number of bits */
#define BYTE_SIGN_BIT (1U << (BYTE_BIT - 1)) /* 1 in sign bit */
#define BYTE_SHIFT 3 /* Shift to turn bytes into bits */
#define BYTE_MASK ((Byte)-1) /* Mask for a byte */

#define INST_BYTE (sizeof (InstWord)) /* Number of bytes */
#define INST_BIT (sizeof (InstWord) * CHAR_BIT) /* Number of bits */
#define INST_ALIGN (INST_BYTE - 1) /* Mask to align an address */
#define INST_SIGN_BIT (1U << (INST_BIT - 1)) /* 1 in sign bit */
#define INST_SHIFT 2 /* Shift to turn words into bytes */
#define INST_BYTES_LEFT(p) (INST_BYTE - ((uintptr_t)p & INST_ALIGN))
/* maximum number of octal digits in an InstWord (upper bound on max. 
   no. of decimal digits) */
#define INST_MAXLEN (sizeof (InstWord) * CHAR_BIT / 3)


#define WORD_BYTE (sizeof (Word)) /* Number of bytes */
#define WORD_BIT (sizeof (Word) * CHAR_BIT) /* Number of bits */
#define WORD_MASK (WORD_BYTE - 1)
  /* Number of bytes left in the word from p */
#define WORD_BYTES_LEFT(p) (WORD_BYTE - ((uintptr_t)p & WORD_MASK))
  /* Number of bytes left in the word from p */

#define INST_MAXLEN 4096 /* Maximum amount of code generated for an
                            instruction */

#define INIT_IMAGE_SIZE 16384
#define INIT_LABS 256

#endif
